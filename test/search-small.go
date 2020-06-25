package graphqlbackend

import (
	"context"
	"encoding/json"
	"fmt"
	"math"
	"regexp"
	regexpsyntax "regexp/syntax"
	"sort"
	"strconv"
	"strings"
	"sync"

	"github.com/inconshreveable/log15"

	"github.com/neelance/parallel"
	"github.com/pkg/errors"

	"github.com/sourcegraph/sourcegraph/cmd/frontend/db"
	"github.com/sourcegraph/sourcegraph/cmd/frontend/envvar"
	"github.com/sourcegraph/sourcegraph/cmd/frontend/types"
	"github.com/sourcegraph/sourcegraph/internal/api"
	"github.com/sourcegraph/sourcegraph/internal/conf"
	"github.com/sourcegraph/sourcegraph/internal/endpoint"
	"github.com/sourcegraph/sourcegraph/internal/errcode"
	"github.com/sourcegraph/sourcegraph/internal/gitserver"
	"github.com/sourcegraph/sourcegraph/internal/goroutine"
	"github.com/sourcegraph/sourcegraph/internal/lazyregexp"
	"github.com/sourcegraph/sourcegraph/internal/search"
	searchbackend "github.com/sourcegraph/sourcegraph/internal/search/backend"
	"github.com/sourcegraph/sourcegraph/internal/search/query"
	querytypes "github.com/sourcegraph/sourcegraph/internal/search/query/types"
	"github.com/sourcegraph/sourcegraph/internal/trace"
	"github.com/sourcegraph/sourcegraph/internal/vcs"
	"github.com/sourcegraph/sourcegraph/internal/vcs/git"
	"github.com/sourcegraph/sourcegraph/schema"
)

// This file contains the root resolver for search. It currently has a lot of
// logic that spans out into all the other search_* files.
var mockResolveRepositories func(effectiveRepoFieldValues []string) (repoRevs, missingRepoRevs []*search.RepositoryRevisions, excludedRepos *excludedRepos, overLimit bool, err error)

func maxReposToSearch() int {
	switch max := conf.Get().MaxReposToSearch; {
	case max <= 0:
		// Default to a very large number that will not overflow if incremented.
		return math.MaxInt32 >> 1
	default:
		return max
	}
}

type SearchArgs struct {
	Version        string
	PatternType    *string
	Query          string
	After          *string
	First          *int32
	VersionContext *string
}

type SearchImplementer interface {
	Results(context.Context) (*SearchResultsResolver, error)
	Suggestions(context.Context, *searchSuggestionsArgs) ([]*searchSuggestionResolver, error)
	//lint:ignore U1000 is used by graphql via reflection
	Stats(context.Context) (*searchResultsStats, error)
}
