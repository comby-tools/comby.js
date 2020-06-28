curl -d '{"source": "hi", "match": "hi", "rewrite": "bye"}' -H "Content-Type: application/json" -X POST http://localhost:3289/rewrite

