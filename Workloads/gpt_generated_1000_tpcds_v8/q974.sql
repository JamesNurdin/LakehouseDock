WITH ss_sample AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows
),
ss_part AS (
    SELECT
        ss.ss_sold_date_sk                                   AS date_sk,
        d.d_year                                            AS year,
        s.s_store_name                                      AS location_name,
        sh.t_shift                                          AS shift,
        v.grp                                               AS grp,
        CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_category,
        SUM(ss.ss_ext_sales_price)                          AS total_sales,
        SUM(ss.ss_net_profit)                               AS total_profit,
        SUM(COALESCE(lr.total_ret, 0))                      AS total_ret
    FROM ss_sample ss
    JOIN date_dim d       ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s          ON ss.ss_store_sk     = s.s_store_sk
    JOIN promotion p      ON ss.ss_promo_sk     = p.p_promo_sk
    -- small dimension for cross join
    CROSS JOIN (SELECT DISTINCT t_shift FROM time_dim WHERE t_shift = 'first') AS sh
    CROSS JOIN (VALUES (1), (2)) AS v (grp)
    LEFT JOIN LATERAL (
        SELECT SUM(sr_return_amt) AS total_ret
        FROM store_returns sr
        WHERE sr.sr_ticket_number = ss.ss_ticket_number
    ) lr ON true
    WHERE EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_ticket_number = ss.ss_ticket_number
    )
      AND d.d_year = 2001
    GROUP BY
        ss.ss_sold_date_sk,
        d.d_year,
        s.s_store_name,
        sh.t_shift,
        v.grp,
        CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END
),
cs_part AS (
    SELECT
        cs.cs_sold_date_sk                                   AS date_sk,
        d.d_year                                            AS year,
        w.w_warehouse_name                                  AS location_name,
        sh2.t_shift                                         AS shift,
        v2.grp                                              AS grp,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_category,
        SUM(cs.cs_ext_sales_price)                          AS total_sales,
        SUM(cs.cs_net_profit)                               AS total_profit,
        SUM(COALESCE(lr2.total_ret, 0))                     AS total_ret
    FROM catalog_sales cs
    JOIN date_dim d        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w       ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p       ON cs.cs_promo_sk    = p.p_promo_sk
    -- small dimension for cross join
    CROSS JOIN (SELECT DISTINCT t_shift FROM time_dim WHERE t_shift = 'second') AS sh2
    CROSS JOIN (VALUES (1), (2), (3)) AS v2 (grp)
    LEFT JOIN LATERAL (
        SELECT SUM(sr_return_amt) AS total_ret
        FROM store_returns sr
        WHERE sr.sr_item_sk = cs.cs_item_sk
    ) lr2 ON true
    WHERE EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_item_sk = cs.cs_item_sk
    )
      AND d.d_year = 2001
    GROUP BY
        cs.cs_sold_date_sk,
        d.d_year,
        w.w_warehouse_name,
        sh2.t_shift,
        v2.grp,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END
)
SELECT *
FROM (
    SELECT * FROM ss_part
    UNION ALL
    SELECT * FROM cs_part
) AS combined
ORDER BY profit_category DESC, total_sales DESC
LIMIT 100
