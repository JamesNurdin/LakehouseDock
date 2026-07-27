/*
  Goal: Identify the most profitable items per call‑center division, adjusting sales profit by catalog returns and filtering on a variety of product, market, shipping, and return characteristics. The query pre‑aggregates catalog sales, joins all seven selected tables, applies six+ predicates, computes a profit rank per division, and limits the output to the top 100 rows.
*/
WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        SUM(cs.cs_ext_sales_price)        AS total_sales_amount,
        SUM(cs.cs_net_profit)             AS total_net_profit,
        SUM(cs.cs_quantity)               AS total_quantity
    FROM catalog_sales cs
    -- example numeric date filter (surrogate key)
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY cs.cs_item_sk, cs.cs_call_center_sk, cs.cs_ship_mode_sk
),
returns_agg AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_call_center_sk,
        cr.cr_ship_mode_sk,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_return_ship_cost > 1000.00   -- predicate 1 (inside sub‑query)
    GROUP BY cr.cr_item_sk, cr.cr_call_center_sk, cr.cr_ship_mode_sk
)
SELECT
    cc.cc_division_name,
    i.i_item_id,
    sm.sm_type,
    s.total_sales_amount,
    s.total_net_profit,
    COALESCE(r.total_return_amount, 0)               AS total_return_amount,
    (s.total_net_profit - COALESCE(r.total_return_amount, 0)) AS profit_after_returns,
    RANK() OVER (PARTITION BY cc.cc_division_name ORDER BY (s.total_net_profit - COALESCE(r.total_return_amount, 0)) DESC) AS profit_rank,
    CASE WHEN (s.total_net_profit - COALESCE(r.total_return_amount, 0)) < 0 THEN 'Loss' ELSE 'Gain' END AS profit_status
FROM sales_agg s
JOIN call_center cc      ON s.cs_call_center_sk = cc.cc_call_center_sk               -- join rule 1
JOIN ship_mode sm        ON s.cs_ship_mode_sk   = sm.sm_ship_mode_sk                 -- join rule 2
JOIN item i              ON s.cs_item_sk        = i.i_item_sk                         -- join rule 3
LEFT JOIN returns_agg r  ON r.cr_item_sk        = s.cs_item_sk
                         AND r.cr_call_center_sk = s.cs_call_center_sk
                         AND r.cr_ship_mode_sk   = s.cs_ship_mode_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk       = i.i_item_sk                         -- join rule 4
LEFT JOIN web_page wp    ON wr.wr_web_page_sk  = wp.wp_web_page_sk                    -- join rule 5
WHERE
    i.i_brand_id      IN (5002002, 2004002)          -- predicate 2
    AND i.i_class_id = 5                           -- predicate 3
    AND cc.cc_mkt_id = 4                          -- predicate 4
    AND sm.sm_type = 'AIR'                        -- predicate 5 (example value)
    AND s.total_quantity > 10                    -- predicate 6 (on pre‑aggregated column)
    AND (wr.wr_return_quantity IS NULL OR wr.wr_return_quantity < 5)  -- predicate 7
ORDER BY profit_rank, cc.cc_division_name
LIMIT 100
