/*
  Goal: Produce a deep‑join analytical report that combines all 12 selected TPC‑DS tables, samples the store_sales fact table, uses a FULL OUTER JOIN between catalog_returns and web_sales, re‑uses the ship_mode dimension under two aliases, computes subtotals with ROLLUP, assigns a ROW_NUMBER per store, and returns the top 100 rows ordered by store and category.
*/
WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)   -- sample 10 % of the rows
),
joined_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        td.t_hour,
        i.i_category,
        i.i_brand,
        cd.cd_gender,
        ca.ca_state,
        s.s_store_name,
        p.p_promo_name,
        sm2.sm_code               AS return_ship_mode,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        ws.ws_web_page_sk,
        ws.ws_net_profit          AS web_net_profit,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY ss.ss_net_profit DESC) AS rn
    FROM sampled_sales ss
    LEFT JOIN time_dim td            ON ss.ss_sold_time_sk   = td.t_time_sk
    LEFT JOIN item i                 ON ss.ss_item_sk        = i.i_item_sk
    LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk     = cd.cd_demo_sk
    LEFT JOIN customer_address ca    ON ss.ss_addr_sk        = ca.ca_address_sk
    LEFT JOIN store s                ON ss.ss_store_sk       = s.s_store_sk
    LEFT JOIN promotion p            ON ss.ss_promo_sk       = p.p_promo_sk
    LEFT JOIN store_returns sr       ON sr.sr_item_sk        = ss.ss_item_sk
                                   AND sr.sr_store_sk       = s.s_store_sk
    LEFT JOIN web_sales ws           ON ws.ws_item_sk        = i.i_item_sk
    LEFT JOIN catalog_returns cr     ON cr.cr_item_sk        = i.i_item_sk
    LEFT JOIN catalog_page cp        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm2          ON cr.cr_ship_mode_sk   = sm2.sm_ship_mode_sk
),
full_joined AS (
    SELECT
        cr2.cr_returned_date_sk,
        cr2.cr_return_quantity,
        ws2.ws_sold_date_sk,
        ws2.ws_quantity,
        i2.i_category,
        sm3.sm_code               AS ship_mode_code
    FROM catalog_returns cr2
    LEFT JOIN ship_mode sm3        ON cr2.cr_ship_mode_sk = sm3.sm_ship_mode_sk
    INNER JOIN item i2             ON cr2.cr_item_sk       = i2.i_item_sk
    FULL OUTER JOIN web_sales ws2  ON ws2.ws_item_sk       = i2.i_item_sk
)
SELECT
    COALESCE(jd.s_store_name, 'Grand Total') AS store_name,
    COALESCE(jd.i_category, 'Grand Total')   AS category,
    SUM(jd.ss_ext_sales_price)               AS total_sales,
    SUM(jd.ss_net_profit)                    AS total_profit,
    SUM(jd.sr_net_loss)                      AS total_return_loss,
    SUM(jd.web_net_profit)                   AS total_web_profit,
    SUM(jd.cr_return_amount)                 AS total_catalog_return_amount,
    MAX(jd.rn)                               AS max_row_number
FROM joined_data jd
LEFT JOIN full_joined fj
    ON jd.i_category = fj.i_category          -- keep the FULL OUTER join branch in the plan
GROUP BY ROLLUP (jd.s_store_name, jd.i_category)
ORDER BY store_name ASC, category ASC
LIMIT 100
