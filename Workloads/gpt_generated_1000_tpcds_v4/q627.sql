WITH filtered_items AS (
    SELECT
        i.i_item_sk,
        i.i_class,
        i.i_formulation,
        regexp_extract(i.i_formulation, '(\\d+)', 1) AS formulation_code
    FROM tpcds.item i
    WHERE i.i_formulation LIKE '%peru%'
      AND regexp_like(i.i_formulation, '[0-9]{3,}')
),
sales_agg AS (
    SELECT
        fi.i_item_sk,
        fi.i_class,
        fi.formulation_code,
        SUM(cs.cs_net_profit) AS total_profit
    FROM filtered_items fi
    JOIN tpcds.catalog_sales cs
        ON cs.cs_item_sk = fi.i_item_sk
    JOIN tpcds.date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY fi.i_item_sk, fi.i_class, fi.formulation_code
),
returns_agg AS (
    SELECT
        fi.i_item_sk,
        r.r_reason_desc,
        SUM(sr.sr_net_loss) AS total_loss
    FROM filtered_items fi
    JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = fi.i_item_sk
    JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, 'work')
    GROUP BY fi.i_item_sk, r.r_reason_desc
)
SELECT
    s.i_class,
    s.formulation_code,
    s.total_profit,
    r.r_reason_desc,
    r.total_loss
FROM sales_agg s
JOIN returns_agg r
    ON s.i_item_sk = r.i_item_sk
ORDER BY s.total_profit DESC
LIMIT 100
