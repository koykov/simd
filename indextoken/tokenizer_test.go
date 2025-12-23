package indextoken

import (
	"reflect"
	"strconv"
	"testing"
)

type stageR struct {
	source    string
	tokens    []string
	tokensSQB []string
	tokensAt  []string
}

var stagesR = []stageR{
	{source: "", tokens: nil},
	{source: "..", tokens: nil},
	{source: ".", tokens: nil},
	{source: "[]", tokens: nil},
	{source: "@", tokens: nil},
	{source: "[0]", tokens: []string{"0"}, tokensSQB: []string{"[0]"}},
	{source: "single", tokens: []string{"single"}},
	{source: "@tag", tokens: []string{"tag"}, tokensAt: []string{"@tag"}},
	{source: "a.b.c", tokens: []string{"a", "b", "c"}},

	{source: "user.profile.email", tokens: []string{"user", "profile", "email"}},
	{source: "data[0].value", tokens: []string{"data", "0", "value"}, tokensSQB: []string{"data", "[0]", "value"}},
	{source: "config.database.host@primary", tokens: []string{"config", "database", "host", "primary"},
		tokensAt: []string{"config", "database", "host", "@primary"}},
	{source: "api.users[123].name", tokens: []string{"api", "users", "123", "name"},
		tokensSQB: []string{"api", "users", "[123]", "name"}},

	{source: "request.headers.authorization", tokens: []string{"request", "headers", "authorization"}},
	{source: "response.body.data[0].id", tokens: []string{"response", "body", "data", "0", "id"},
		tokensSQB: []string{"response", "body", "data", "[0]", "id"}},
	{source: "app.routes.api.v1.users", tokens: []string{"app", "routes", "api", "v1", "users"}},
	{source: "server.ports[8080].protocol@http", tokens: []string{"server", "ports", "8080", "protocol", "http"},
		tokensSQB: []string{"server", "ports", "[8080]", "protocol", "http"},
		tokensAt:  []string{"server", "ports", "8080", "protocol", "@http"}},

	{source: "system.cpu.usage", tokens: []string{"system", "cpu", "usage"}},
	{source: "disk.partitions[0].size@gb", tokens: []string{"disk", "partitions", "0", "size", "gb"},
		tokensSQB: []string{"disk", "partitions", "[0]", "size", "gb"},
		tokensAt:  []string{"disk", "partitions", "0", "size", "@gb"}},
	{source: "network.interfaces.eth0.ip", tokens: []string{"network", "interfaces", "eth0", "ip"}},
	{source: "log.files.app[2023].size", tokens: []string{"log", "files", "app", "2023", "size"},
		tokensSQB: []string{"log", "files", "app", "[2023]", "size"}},

	{source: "db.tables.users.columns.id", tokens: []string{"db", "tables", "users", "columns", "id"}},
	{source: "query.results[5].name", tokens: []string{"query", "results", "5", "name"},
		tokensSQB: []string{"query", "results", "[5]", "name"}},
	{source: "schema.public.tables.orders", tokens: []string{"schema", "public", "tables", "orders"}},
	{source: "index.primary.keys[0]@unique", tokens: []string{"index", "primary", "keys", "0", "unique"},
		tokensSQB: []string{"index", "primary", "keys", "[0]", "unique"},
		tokensAt:  []string{"index", "primary", "keys", "0", "@unique"}},

	{source: "object.properties.length", tokens: []string{"object", "properties", "length"}},
	{source: "array.items[99].value", tokens: []string{"array", "items", "99", "value"},
		tokensSQB: []string{"array", "items", "[99]", "value"}},
	{source: "function.parameters.args[0]", tokens: []string{"function", "parameters", "args", "0"},
		tokensSQB: []string{"function", "parameters", "args", "[0]"}},
	{source: "class.methods.static.validate", tokens: []string{"class", "methods", "static", "validate"}},

	{source: "matrix.rows[0].cells[1]", tokens: []string{"matrix", "rows", "0", "cells", "1"},
		tokensSQB: []string{"matrix", "rows", "[0]", "cells", "[1]"}},
	{source: "grid.points[x].coordinates[y]", tokens: []string{"grid", "points", "x", "coordinates", "y"},
		tokensSQB: []string{"grid", "points", "[x]", "coordinates", "[y]"}},
	{source: "list.items[i].subitems[j]", tokens: []string{"list", "items", "i", "subitems", "j"},
		tokensSQB: []string{"list", "items", "[i]", "subitems", "[j]"}},

	{source: ".start.empty", tokens: []string{"start", "empty"}},
	{source: "end.empty.", tokens: []string{"end", "empty"}},
	{source: "multiple..empty..tokens", tokens: []string{"multiple", "empty", "tokens"}},
	{source: "[].empty.brackets", tokens: []string{"empty", "brackets"}},
	{source: "test..data[].value", tokens: []string{"test", "data", "value"}},

	{source: "user-name.first@company", tokens: []string{"user-name", "first", "company"},
		tokensAt: []string{"user-name", "first", "@company"}},
	{source: "file.name.with.dots.txt", tokens: []string{"file", "name", "with", "dots", "txt"}},
	{source: "path.with-dashes.config", tokens: []string{"path", "with-dashes", "config"}},

	{source: "api.v2.users[42].profile.email@work", tokens: []string{"api", "v2", "users", "42", "profile", "email", "work"},
		tokensSQB: []string{"api", "v2", "users", "[42]", "profile", "email", "work"},
		tokensAt:  []string{"api", "v2", "users", "42", "profile", "email", "@work"}},
	{source: "system.metrics.cpu[0].usage@percent", tokens: []string{"system", "metrics", "cpu", "0", "usage", "percent"},
		tokensSQB: []string{"system", "metrics", "cpu", "[0]", "usage", "percent"},
		tokensAt:  []string{"system", "metrics", "cpu", "0", "usage", "@percent"}},
	{source: "db.primary.tables[customers].rows[0].id", tokens: []string{"db", "primary", "tables", "customers", "rows", "0", "id"},
		tokensSQB: []string{"db", "primary", "tables", "[customers]", "rows", "[0]", "id"}},

	{source: "github.api.repos.owner.name", tokens: []string{"github", "api", "repos", "owner", "name"}},
	{source: "docker.containers[app].ports[80]", tokens: []string{"docker", "containers", "app", "ports", "80"},
		tokensSQB: []string{"docker", "containers", "[app]", "ports", "[80]"}},
	{source: "kubernetes.pods.nginx.status@running", tokens: []string{"kubernetes", "pods", "nginx", "status", "running"},
		tokensAt: []string{"kubernetes", "pods", "nginx", "status", "@running"}},
	{source: "aws.s3.buckets[my-bucket].files[0]", tokens: []string{"aws", "s3", "buckets", "my-bucket", "files", "0"},
		tokensSQB: []string{"aws", "s3", "buckets", "[my-bucket]", "files", "[0]"}},

	{source: "json.employees[0].skills[1].level", tokens: []string{"json", "employees", "0", "skills", "1", "level"},
		tokensSQB: []string{"json", "employees", "[0]", "skills", "[1]", "level"}},
	{source: "config.app.theme.colors.primary", tokens: []string{"config", "app", "theme", "colors", "primary"}},
	{source: "settings.notifications.email.enabled", tokens: []string{"settings", "notifications", "email", "enabled"}},

	{source: "url.domain.com.path.api.v1", tokens: []string{"url", "domain", "com", "path", "api", "v1"}},
	{source: "fs.home.users.john.documents[0]", tokens: []string{"fs", "home", "users", "john", "documents", "0"},
		tokensSQB: []string{"fs", "home", "users", "john", "documents", "[0]"}},

	{source: "products[first].name", tokens: []string{"products", "first", "name"},
		tokensSQB: []string{"products", "[first]", "name"}},
	{source: "items[last].price", tokens: []string{"items", "last", "price"},
		tokensSQB: []string{"items", "[last]", "price"}},
	{source: "elements[42_1].value", tokens: []string{"elements", "42_1", "value"},
		tokensSQB: []string{"elements", "[42_1]", "value"}},

	{source: "data.raw.temperature@celsius", tokens: []string{"data", "raw", "temperature", "celsius"},
		tokensAt: []string{"data", "raw", "temperature", "@celsius"}},
	{source: "user.session.token@expired", tokens: []string{"user", "session", "token", "expired"},
		tokensAt: []string{"user", "session", "token", "@expired"}},
	{source: "file.backup.archive@compressed", tokens: []string{"file", "backup", "archive", "compressed"},
		tokensAt: []string{"file", "backup", "archive", "@compressed"}},

	{source: "company.departments.engineering.teams.backend.employees[5].profile.contact.phone",
		tokens:    []string{"company", "departments", "engineering", "teams", "backend", "employees", "5", "profile", "contact", "phone"},
		tokensSQB: []string{"company", "departments", "engineering", "teams", "backend", "employees", "[5]", "profile", "contact", "phone"}},
	{source: "system.hardware.motherboard.cpu.cores[0].cache.l1",
		tokens:    []string{"system", "hardware", "motherboard", "cpu", "cores", "0", "cache", "l1"},
		tokensSQB: []string{"system", "hardware", "motherboard", "cpu", "cores", "[0]", "cache", "l1"}},

	{source: "..test..data[42]..value@final", tokens: []string{"test", "data", "42", "value", "final"},
		tokensSQB: []string{"test", "data", "[42]", "value", "final"},
		tokensAt:  []string{"test", "data", "42", "value", "@final"}},
	{source: "start.[0].middle[].end@", tokens: []string{"start", "0", "middle", "end"},
		tokensSQB: []string{"start", "[0]", "middle", "end"},
		tokensAt:  []string{"start", "0", "middle", "end"}},
	{source: "@global.config..servers[primary].host", tokens: []string{"global", "config", "servers", "primary", "host"},
		tokensSQB: []string{"global", "config", "servers", "[primary]", "host"},
		tokensAt:  []string{"@global", "config", "servers", "primary", "host"}},

	{source: "game.players[hero].inventory.weapons[0].damage", tokens: []string{"game", "players", "hero", "inventory", "weapons", "0", "damage"},
		tokensSQB: []string{"game", "players", "[hero]", "inventory", "weapons", "[0]", "damage"}},
	{source: "car.engine.cylinders[3].pressure@psi", tokens: []string{"car", "engine", "cylinders", "3", "pressure", "psi"},
		tokensSQB: []string{"car", "engine", "cylinders", "[3]", "pressure", "psi"},
		tokensAt:  []string{"car", "engine", "cylinders", "3", "pressure", "@psi"}},
	{source: "weather.stations[NYC].sensors.temperature", tokens: []string{"weather", "stations", "NYC", "sensors", "temperature"},
		tokensSQB: []string{"weather", "stations", "[NYC]", "sensors", "temperature"}},

	{source: "array[0][1][2]", tokens: []string{"array", "0", "1", "2"}, tokensSQB: []string{"array", "[0]", "[1]", "[2]"}},
	{source: "matrix[10][20].value", tokens: []string{"matrix", "10", "20", "value"},
		tokensSQB: []string{"matrix", "[10]", "[20]", "value"}},
	{source: "deep.nested[1].array[2].item[3]", tokens: []string{"deep", "nested", "1", "array", "2", "item", "3"},
		tokensSQB: []string{"deep", "nested", "[1]", "array", "[2]", "item", "[3]"}},
}

func TestTokenizer(t *testing.T) {
	t.Run("no flags", func(t *testing.T) {
		for i := range stagesR {
			stg := &stagesR[i]
			t.Run(strconv.Itoa(i), func(t *testing.T) {
				var tkn Tokenizer[string]
				var r []string
				for {
					if tt := tkn.Next(stg.source); len(tt) > 0 {
						r = append(r, tt)
						continue
					}
					break
				}
				if !reflect.DeepEqual(r, stg.tokens) {
					t.Errorf("tokens mismatch. got %v, expected %v", r, stg.tokens)
				}
			})
		}
	})
	t.Run("sqb", func(t *testing.T) {
		for i := range stagesR {
			stg := &stagesR[i]
			if len(stg.tokensSQB) == 0 {
				continue
			}
			t.Run(strconv.Itoa(i), func(t *testing.T) {
				var tkn Tokenizer[string]
				tkn.KeepSquareBrackets()
				var r []string
				for {
					if tt := tkn.Next(stg.source); len(tt) > 0 {
						r = append(r, tt)
						continue
					}
					break
				}
				if !reflect.DeepEqual(r, stg.tokensSQB) {
					t.Errorf("tokens mismatch. got %v, expected %v", r, stg.tokensSQB)
				}
			})
		}
	})
	t.Run("at", func(t *testing.T) {
		for i := range stagesR {
			stg := &stagesR[i]
			if len(stg.tokensAt) == 0 {
				continue
			}
			t.Run(strconv.Itoa(i), func(t *testing.T) {
				var tkn Tokenizer[string]
				tkn.KeepAt()
				var r []string
				for {
					if tt := tkn.Next(stg.source); len(tt) > 0 {
						r = append(r, tt)
						continue
					}
					break
				}
				if !reflect.DeepEqual(r, stg.tokensAt) {
					t.Errorf("tokens mismatch. got %v, expected %v", r, stg.tokensAt)
				}
			})
		}
	})
}

func BenchmarkTokenizer(b *testing.B) {
	var buf []string
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		stg := &stagesR[i%len(stagesR)]
		var tkn Tokenizer[string]
		buf = buf[:0]
		for {
			if tt := tkn.Next(stg.source); len(tt) > 0 {
				buf = append(buf, tt)
				continue
			}
			break
		}
	}
}
