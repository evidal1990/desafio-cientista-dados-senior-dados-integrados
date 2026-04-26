# Inventário de chaves e contratos por model

Contratos **declarativos** (principalmente `models/staging/schema.yml` e `models/marts/schema.yml`) e grãos lógicos inferidos dos SQL em `models/staging/*.sql` e `models/marts/*.sql`.  
Tipos físicos no Postgres seguem os casts dos `stg_*` (ex.: `bigint`, `double precision`, `text`, `date`).

**Documentação por teste:** README §10 — tabelas *Coluna / Teste / Por quê* para **marts** (`models/marts/schema.yml`) e para **staging** (`models/staging/schema.yml`); os YAML mantêm só a declaração dos testes.

Legenda:

- **PK natural**: identificador único de negócio da tabela no grão do model (pode coincidir com surrogate na fonte).
- **FK esperada**: referência que o projeto testa (`relationships`) ou que o join de negócio assume.
- **Enums / categorias estáveis**: `accepted_values` ou domínio documentado.
- **Obrigatório negócio**: `not_null` nos testes ou requisito explícito do pipeline downstream (ex.: `int_media_*`).

---

## `stg_aluno`

| Conceito | Detalhe |
|----------|---------|
| **Grão** | Uma linha por **aluno** (`id_aluno` testado como `unique`). |
| **PK natural** | `id_aluno`. |
| **FKs esperadas** | *Nenhum* `relationships` no schema; downstream assume vínculo com `id_turma` coerente com `stg_turma` e notas em `stg_avaliacao` na chave `(id_aluno, id_turma)`. |
| **Enums / categorias** | `faixa_etaria` ∈ `0-5`, `6-10`, `11-14`, `15-17`, `18+`. |
| **Obrigatório negócio** | `id_aluno`, `id_turma`, `faixa_etaria`. `bairro`: teste `not_null` com limiares de falha — na fonte real podem existir nulos (tratados no `int_media_disciplina_por_aluno` com `bairro is not null`). |

**Unicidade adicional (teste):** combinação `(id_aluno, id_turma, faixa_etaria, bairro)`.

---

## `stg_escola`

| Conceito | Detalhe |
|----------|---------|
| **Grão** | Uma linha por **escola**. |
| **PK natural** | `id_escola` (`unique`). |
| **FKs esperadas** | *Nenhuma* referência de saída testada; `stg_frequencia.id_escola` → `stg_escola.id_escola`. |
| **Enums / categorias** | *Nenhum* `accepted_values` além do domínio implícito (hash) em `bairro`. |
| **Obrigatório negócio** | `id_escola`, `bairro` (`not_null`; `bairro` também `unique` no schema — reflete contrato da carga, não regra de negócio universal). |

---

## `stg_turma`

| Conceito | Detalhe |
|----------|---------|
| **Grão** | Uma linha por **vínculo aluno × turma** (ano letivo anonimizado). |
| **PK natural** | `(ano, id_turma, id_aluno)` (teste `unique_combination_of_columns`). |
| **FKs esperadas** | `id_aluno` → `stg_aluno.id_aluno` (`relationships`). |
| **Enums / categorias** | `ano` = **2000** (valor único aceite — anonimização). |
| **Obrigatório negócio** | `ano`, `id_turma`, `id_aluno`. |

---

## `stg_frequencia`

| Conceito | Detalhe |
|----------|---------|
| **Grão** | Uma linha por **período × disciplina × (escola, aluno, turma)** na granularidade da fonte. |
| **PK natural** | `(id_escola, id_aluno, id_turma, data_inicio, data_fim, disciplina, frequencia)` (teste `unique_combination_of_columns`). |
| **FKs esperadas** | `id_escola` → `stg_escola.id_escola`; `id_aluno` → `stg_aluno.id_aluno`; `id_turma` → `stg_turma.id_turma`. |
| **Enums / categorias** | `disciplina` ∈ `lingua_portuguesa`, `ciencias`, `ingles`, `matematica`. Datas no ano **2000** (expressões `expression_is_true` no schema). |
| **Obrigatório negócio** | Todas as colunas do model com `not_null`; `frequencia` ∈ [0, 100]. |

---

## `stg_avaliacao`

| Conceito | Detalhe |
|----------|---------|
| **Grão** | Uma linha por **aluno × turma × bimestre**. |
| **PK natural** | `(id_aluno, id_turma, bimestre)` (`unique_combination_of_columns`). |
| **FKs esperadas** | `id_aluno` → `stg_aluno.id_aluno`; `id_turma` → `stg_turma.id_turma`. |
| **Enums / categorias** | `bimestre` ∈ [1, 4] (inteiro); notas `lingua_portuguesa`, `ciencias`, `ingles`, `matematica` ∈ [0, 10]; `frequencia` ∈ [0, 100]. |
| **Obrigatório negócio** | Todas as colunas listadas com `not_null` no schema. **Nota:** na fonte de referência, `ingles` pode vir **todo nulo**; o contrato `not_null` do schema pode falhar — alinhar schema à realidade ou documentar exceção. O `int_media_disciplina_por_aluno` **não** usa inglês. |

---

## `mart_resultado_por_faixa_etaria`

| Conceito | Detalhe |
|----------|---------|
| **Grão** | Uma linha por **faixa etária** presente no resultado agregado. |
| **PK natural** | `faixa_etaria` (`unique`, `not_null`). |
| **FKs esperadas** | *Nenhuma* FK física; chave de negócio derivada de `int_media_disciplina_por_aluno.faixa_etaria`. |
| **Enums / categorias** | `faixa_etaria` ∈ `0-5`, `6-10`, `11-14`, `15-17`, `18+` (nem todas as faixas precisam aparecer se não houver linhas no intermediate). |
| **Obrigatório negócio** | `faixa_etaria`, `total_alunos`, todos os `pct_*` aprovados/reprovados por disciplina; percentuais ∈ [0, 100]. **Invariante de negócio:** por disciplina, aprovado + reprovado = **100%** dos `total_alunos` no grupo (resultado binário no upstream). |

---

## `mart_resultado_por_bairro`

| Conceito | Detalhe |
|----------|---------|
| **Grão** | Uma linha por **bairro** (identificador hash/opaco). |
| **PK natural** | `bairro` (`unique`, `not_null`). |
| **FKs esperadas** | *Nenhuma* FK física; `bairro` alinhado a `stg_aluno.bairro` via `int_media_disciplina_por_aluno`. |
| **Enums / categorias** | `bairro` como inteiro opaco (sem enum nominal). |
| **Obrigatório negócio** | `bairro`, `total_alunos` (≥ 1 no teste `accepted_range`), todos os `pct_*` ∈ [0, 100]. Mesmo invariante **aprovado + reprovado = 100%** por disciplina e grupo. |

---

## Matriz rápida de FKs testadas (`relationships`)

| Model (origem) | Coluna | Destino |
|----------------|--------|---------|
| `stg_turma` | `id_aluno` | `stg_aluno.id_aluno` |
| `stg_frequencia` | `id_escola` | `stg_escola.id_escola` |
| `stg_frequencia` | `id_aluno` | `stg_aluno.id_aluno` |
| `stg_frequencia` | `id_turma` | `stg_turma.id_turma` |
| `stg_avaliacao` | `id_aluno` | `stg_aluno.id_aluno` |
| `stg_avaliacao` | `id_turma` | `stg_turma.id_turma` |
| `mart_resultado_por_faixa_etaria` | `faixa_etaria` | `stg_aluno.faixa_etaria` (dimensão herdada; sem fan-out) |
| `mart_resultado_por_bairro` | `bairro` | `stg_aluno.bairro` (proveniência do cadastro de aluno; **não** `stg_escola.bairro`) |

O `int_media_disciplina_por_aluno` (intermediate) assume ainda **inner join** com `stg_aluno` e `stg_turma` em `(id_aluno, id_turma)` e **filtra** `bairro is not null` e notas núcleo não nulas — contrato de **população analítica**, não listado como `stg_*` acima.

---

*Última revisão alinhada aos ficheiros `models/staging/schema.yml` e `models/marts/schema.yml` do repositório.*
