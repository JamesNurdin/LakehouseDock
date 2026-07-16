WITH
    cte_sales AS (
        SELECT
            cs.cs_order_number,
            cs.cs_sold_date_sk,
            cs.cs_item_sk,
            cs.cs_quantity,
            cs.cs_ext_sales_price,
            cs.cs_net_profit,
            cs.cs_call_center_sk,
            cs.cs_ship_mode_sk,
            cs.cs_warehouse_sk,
            i.i_category,
            cc.cc_name,
            d.d_year,
            ROW_NUMBER() OVER (PARTITION BY cs.cs_order_number ORDER BY cs.cs_ext_sales_price DESC) AS rn,
            SUM(cs.cs_ext_sales_price) OVER (PARTITION BY cs.cs_item_sk) AS sum_item_sales,
            AVG(cs.cs_ext_sales_price) OVER (PARTITION BY cs.cs_call_center_sk) AS avg_call_center_sales
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE cs.cs_quantity > 0
    ),
    cte_returns AS (
        SELECT
            cr.cr_order_number,
            cr.cr_return_amount,
            cr.cr_return_quantity,
            cr.cr_returned_date_sk,
            CASE
                WHEN cr.cr_return_amount > 0 THEN 'POSITIVE'
                WHEN cr.cr_return_amount < 0 THEN 'NEGATIVE'
                ELSE NULL
            END AS return_sign,
            r.r_reason_desc,
            d.d_year AS return_year
        FROM catalog_returns cr
        LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        LEFT JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    ),
    cte_latest_store AS (
        SELECT
            ss.ss_item_sk,
            ss.ss_store_sk,
            s.s_store_name,
            ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY ss.ss_sold_date_sk DESC NULLS LAST) AS rn_latest_store
        FROM store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        WHERE ss.ss_quantity IS NOT NULL
    ),
    cte_complex AS (
        SELECT
            c.cs_order_number,
            c.cs_item_sk,
            c.cs_ext_sales_price,
            c.cs_quantity,
            c.cs_net_profit,
            c.i_category,
            c.d_year,
            c.cc_name,
            COALESCE(r.cr_return_amount, 0) AS return_amount,
            COALESCE(r.cr_return_quantity, 0) AS return_quantity,
            CASE
                WHEN c.cc_name IS NULL OR c.cc_name = '' THEN 'UNKNOWN_CC'
                ELSE c.cc_name
            END AS call_center_name,
            CONCAT(COALESCE(c.i_category, 'UNCAT'), '-', COALESCE(CAST(c.d_year AS VARCHAR), '0')) AS cat_year_key,
            (c.cs_ext_sales_price - COALESCE(r.cr_return_amount, 0)) / NULLIF(c.cs_quantity, 0) AS net_price_per_unit,
            RANK() OVER (PARTITION BY c.i_category ORDER BY c.cs_ext_sales_price DESC) AS category_rank,
            (SELECT MAX(cr2.cr_return_amount) FROM catalog_returns cr2 WHERE cr2.cr_order_number = c.cs_order_number) AS max_return_amount,
            (SELECT COUNT(DISTINCT cr2.cr_reason_sk) FROM catalog_returns cr2 WHERE cr2.cr_order_number = c.cs_order_number) AS distinct_return_reasons
        FROM cte_sales c
        LEFT JOIN cte_returns r ON c.cs_order_number = r.cr_order_number
    )
SELECT
    cc_comb.cs_order_number,
    cc_comb.call_center_name,
    cc_comb.cat_year_key,
    cc_comb.cs_ext_sales_price,
    cc_comb.return_amount,
    cc_comb.net_price_per_unit,
    cc_comb.category_rank,
    CASE
        WHEN cc_comb.return_amount > 0 THEN 'REFUND'
        WHEN cc_comb.cs_ext_sales_price > 1000 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS risk_category,
    COALESCE(ls.s_store_name, 'NO_STORE') AS latest_store_name,
    COALESCE(ls.s_store_name, 'NO_STORE') || '_' || CAST(cc_comb.cs_order_number AS VARCHAR) AS composite_key,
    web.ws_ext_sales_price,
    web.ws_quantity,
    web.d_year AS web_year,
    web.sm_type,
    web.p_promo_name,
    web.net_profit,
    cc_comb.max_return_amount,
    cc_comb.distinct_return_reasons
FROM cte_complex cc_comb
LEFT JOIN (
    SELECT ss_item_sk, s_store_name
    FROM cte_latest_store
    WHERE rn_latest_store = 1
) ls ON cc_comb.cs_item_sk = ls.ss_item_sk
FULL OUTER JOIN (
    SELECT
        ws.ws_order_number AS order_num,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        d.d_year,
        sm.sm_type,
        p.p_promo_name,
        COALESCE(ws.ws_net_profit, 0) AS net_profit
    FROM web_sales ws
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_quantity > 0
) web ON cc_comb.cs_order_number = web.order_num
WHERE (cc_comb.cs_ext_sales_price > 500 OR web.ws_ext_sales_price > 500)
  AND (cc_comb.return_amount IS NULL OR cc_comb.return_amount < cc_comb.cs_ext_sales_price)
  AND (ls.s_store_name IS NOT NULL OR web.ws_ext_sales_price IS NOT NULL)

UNION ALL

SELECT
    NULL AS cs_order_number,
    'AGG' AS call_center_name,
    NULL AS cat_year_key,
    SUM(cc_comb.cs_ext_sales_price) AS cs_ext_sales_price,
    SUM(cc_comb.return_amount) AS return_amount,
    NULL AS net_price_per_unit,
    NULL AS category_rank,
    NULL AS risk_category,
    NULL AS latest_store_name,
    'AGG_SUM' AS composite_key,
    SUM(web.ws_ext_sales_price) AS ws_ext_sales_price,
    NULL AS ws_quantity,
    NULL AS web_year,
    NULL AS sm_type,
    NULL AS p_promo_name,
    SUM(web.net_profit) AS net_profit,
    MAX(cc_comb.max_return_amount) AS max_return_amount,
    SUM(cc_comb.distinct_return_reasons) AS distinct_return_reasons
FROM cte_complex cc_comb
FULL OUTER JOIN (
    SELECT
        ws.ws_order_number AS order_num,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        d.d_year,
        sm.sm_type,
        p.p_promo_name,
        COALESCE(ws.ws_net_profit, 0) AS net_profit
    FROM web_sales ws
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_quantity > 0
) web ON cc_comb.cs_order_number = web.order_num
WHERE (cc_comb.cs_ext_sales_price > 500 OR web.ws_ext_sales_price > 500)
  AND (cc_comb.return_amount IS NULL OR cc_comb.return_amount < cc_comb.cs_ext_sales_price)
ORDER BY cs_ext_sales_price DESC NULLS LAST
LIMIT 200
