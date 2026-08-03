WITH
    sampled_sales AS (
        SELECT *
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    sales_agg AS (
        SELECT
            cd.cd_demo_sk,
            SUM(cs.cs_net_paid) AS total_net_paid,
            SUM(cs.cs_quantity) AS total_quantity,
            COUNT(*) AS sales_cnt,
            ARRAY[cs.cs_quantity, cs.cs_ship_mode_sk] AS qty_ship_arr
        FROM sampled_sales cs
        JOIN customer_demographics cd
            ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        WHERE cs.cs_list_price BETWEEN 80 AND 200                      -- predicate 1
          AND cs.cs_quantity > 1                                      -- predicate 2
          AND cd.cd_purchase_estimate >= 3000                         -- predicate 3
          AND cd.cd_dep_college_count IN (0,1,2,3,4,5)                 -- predicate 4
        GROUP BY cd.cd_demo_sk, cs.cs_quantity, cs.cs_ship_mode_sk
    ),
    sales_unnested AS (
        SELECT
            cd_demo_sk,
            total_net_paid,
            total_quantity,
            sales_cnt,
            v AS qty_or_ship_mode
        FROM sales_agg
        CROSS JOIN UNNEST(qty_ship_arr) AS t(v)
    ),
    returns_agg AS (
        SELECT
            s.s_store_sk,
            s.s_store_name,
            SUM(sr.sr_return_amt) AS total_return_amt,
            SUM(sr.sr_net_loss) AS total_net_loss,
            COUNT(sr.sr_ticket_number) AS returns_cnt
        FROM store_returns sr
        FULL OUTER JOIN store s
            ON sr.sr_store_sk = s.s_store_sk
        LEFT JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
        LEFT JOIN customer_demographics cd2
            ON sr.sr_cdemo_sk = cd2.cd_demo_sk
        WHERE (s.s_gmt_offset BETWEEN -8 AND -5 OR s.s_gmt_offset IS NULL)                     -- predicate 5
          AND (s.s_rec_end_date > DATE '2000-01-01' OR s.s_rec_end_date IS NULL)             -- predicate 6
          AND (sr.sr_return_amt > 50 OR sr.sr_return_amt IS NULL)
          AND (cd2.cd_purchase_estimate IS NULL OR cd2.cd_purchase_estimate < 5000)
        GROUP BY s.s_store_sk, s.s_store_name
    ),
    union_all AS (
        SELECT
            cd_demo_sk AS grp_key,
            total_net_paid AS metric,
            sales_cnt AS cnt,
            'sales' AS src
        FROM sales_unnested
        UNION DISTINCT
        SELECT
            s_store_sk AS grp_key,
            total_return_amt AS metric,
            returns_cnt AS cnt,
            'returns' AS src
        FROM returns_agg
    ),
    final_agg AS (
        SELECT
            grp_key,
            SUM(metric) AS sum_metric,
            SUM(cnt) AS sum_cnt,
            COUNT(DISTINCT src) AS src_types
        FROM union_all
        WHERE EXISTS (SELECT 1 FROM reason r2 WHERE r2.r_reason_desc LIKE '%defect%')
        GROUP BY grp_key
    )
SELECT
    grp_key,
    sum_metric,
    sum_cnt,
    src_types
FROM final_agg
ORDER BY sum_metric DESC
LIMIT 100
