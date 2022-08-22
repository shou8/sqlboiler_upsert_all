{{- $alias := .Aliases.Table .Table.Name -}}
{{- $schemaTable := .Table.Name | .SchemaTable}}

// UpsertAll upserts all rows with the specified column values, using an executor.
// TODO: InsertAll および UpsertAll は多くの共通部分があるためリファクタリングを検討すること #319
func (o {{$alias.UpSingular}}Slice) UpsertAll({{if .NoContext}}exec boil.Executor{{else}}ctx context.Context, exec boil.ContextExecutor{{end}}, updateColumns, insertColumns boil.Columns) error {
    ln := int64(len(o))
    if ln == 0 {
        return nil
    }
    var sql string
    vals := []interface{}{}
    for i, row := range o {
        {{- template "timestamp_upsert_all_helper" . }}

        {{if not .NoHooks -}}
        if err := row.doBeforeInsertHooks(ctx, exec); err != nil {
            return err
        }
        {{- end}}

        nzDefaults := queries.NonZeroDefaultSet({{$alias.DownSingular}}ColumnsWithDefault, row)
        insert, _ := insertColumns.InsertColumnSet(
            {{$alias.DownSingular}}AllColumns,
            {{$alias.DownSingular}}ColumnsWithDefault,
            {{$alias.DownSingular}}ColumnsWithoutDefault,
            nzDefaults,
        )
        if i == 0 {
            sql = "INSERT INTO {{$schemaTable}} " + "({{.LQ}}" + strings.Join(insert, "{{.RQ}},{{.LQ}}") + "{{.RQ}})" + " VALUES "
        }
        sql += strmangle.Placeholders(dialect.UseIndexPlaceholders, len(insert), len(vals)+1, len(insert))
        if i != len(o)-1 {
            sql += ", "
        }
        valMapping, err := queries.BindMapping({{$alias.DownSingular}}Type, {{$alias.DownSingular}}Mapping, insert)
        if err != nil {
            return err
        }
        value := reflect.Indirect(reflect.ValueOf(row))
        vals = append(vals, queries.ValuesFromMapping(value, valMapping)...)
    }

	update := updateColumns.UpdateColumnSet(
	    {{$alias.DownSingular}}AllColumns,
	    {{$alias.DownSingular}}PrimaryKeyColumns,
	)
	if !updateColumns.IsNone() && len(update) == 0 {
	    return errors.New("sqlboilerdao: unable to upsert account_patients, could not build update column list")
	}

    sql += " ON DUPLICATE KEY UPDATE "
    for i, v := range update {
        if i != 0 {
            sql += ","
        }
	    quoted := strmangle.IdentQuote(dialect.LQ, dialect.RQ, v)
        sql += quoted + " = VALUES(" + quoted + ")"
    }

    if boil.DebugMode {
        fmt.Fprintln(boil.DebugWriter, sql)
        fmt.Fprintln(boil.DebugWriter, vals...)
    }

    {{if .NoContext -}}
    _, err := exec.Exec(ctx, sql, vals...)
    {{else -}}
    _, err := exec.ExecContext(ctx, sql, vals...)
    {{end -}}

    if err != nil {
        return errors.Wrap(err, "{{.PkgName}}: unable to insert into {{.Table.Name}}")
    }

    return nil
}

{{- define "timestamp_upsert_all_helper" -}}
    {{- if not .NoAutoTimestamps -}}
    {{- $colNames := .Table.Columns | columnNames -}}
    {{if containsAny $colNames "created_at" "updated_at"}}
        {{if not .NoContext -}}
    if !boil.TimestampsAreSkipped(ctx) {
        {{end -}}
        currTime := time.Now().In(boil.GetLocation())
        {{range $ind, $col := .Table.Columns}}
            {{- if eq $col.Name "created_at" -}}
                {{- if eq $col.Type "time.Time" }}
        if row.CreatedAt.IsZero() {
            row.CreatedAt = currTime
        }
                {{- else}}
        if queries.MustTime(row.CreatedAt).IsZero() {
            queries.SetScanner(&row.CreatedAt, currTime)
        }
                {{- end -}}
            {{- end -}}
            {{- if eq $col.Name "updated_at" -}}
                {{- if eq $col.Type "time.Time"}}
        if row.UpdatedAt.IsZero() {
            row.UpdatedAt = currTime
        }
                {{- else}}
        if queries.MustTime(row.UpdatedAt).IsZero() {
            queries.SetScanner(&row.UpdatedAt, currTime)
        }
                {{- end -}}
            {{- end -}}
        {{end}}
        {{if not .NoContext -}}
    }
        {{end -}}
    {{end}}
    {{- end}}
{{- end -}}
