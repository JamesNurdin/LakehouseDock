WITH
    -- 1️⃣ Sampled and aggregated catalog sales (pre‑aggregation CTE)
    agg_cs AS (
        SELECT
            cs_bill_customer_sk,
            cs_call_center_sk,
            cs_ship_mode_sk,
            cs_promo_sk,
            SUM(cs_ext_sales_price) AS total_sales,
            SUM(cs_net_profit)       AS total_profit,
            COUNT(*)                 AS order_cnt
        FROM tpcds.catalog_sales
        TABLESAMPLE BERNOULLI (10)
        WHERE cs_sold_date_sk IN (
            SELECT d_date_sk
            FROM tpcds.date_dim
            WHERE d_year = 2001
              AND d_month_seq BETWEEN 12 AND 15
        )
        GROUP BY
            cs_bill_customer_sk,
            cs_call_center_sk,
            cs_ship_mode_sk,
            cs_promo_sk
    ),

    -- 2️⃣ Customer rows enriched with the aggregated sales
    cust_sales AS (
        SELECT
            c.c_customer_sk,
            c.c_first_name,
            c.c_last_name,
            c.c_birth_country,
            ca.ca_state,
            cd.cd_gender,
            agg.total_sales,
            agg.total_profit,
            agg.order_cnt,
            agg.cs_call_center_sk,
            agg.cs_ship_mode_sk,
            agg.cs_promo_sk
        FROM tpcds.customer c
        JOIN agg_cs agg
          ON agg.cs_bill_customer_sk = c.c_customer_sk
        JOIN tpcds.customer_address ca
          ON c.c_current_addr_sk = ca.ca_address_sk
        JOIN tpcds.customer_demographics cd
          ON c.c_current_cdemo_sk = cd.cd_demo_sk
    ),

    -- 3️⃣ Store returns FULL OUTER JOIN store (required FULL OUTER JOIN)
    store_full AS (
        SELECT
            sr.sr_returned_date_sk,
            sr.sr_return_time_sk,
            sr.sr_customer_sk,
            sr.sr_store_sk,
            sr.sr_reason_sk,
            sr.sr_return_amt,
            sr.sr_net_loss,
            st.s_store_name,
            st.s_state,
            d.d_year,
            t.t_hour,
            r.r_reason_desc
        FROM tpcds.store_returns sr
        FULL OUTER JOIN tpcds.store st
          ON sr.sr_store_sk = st.s_store_sk
        JOIN tpcds.date_dim d
          ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN tpcds.time_dim t
          ON sr.sr_return_time_sk = t.t_time_sk
        LEFT JOIN tpcds.reason r
          ON sr.sr_reason_sk = r.r_reason_sk
    ),

    -- 4️⃣ Inventory summarized per year (uses DATE_DIM join rule)
    inv_year AS (
        SELECT
            i.inv_item_sk,
            SUM(i.inv_quantity_on_hand) AS qty_on_hand,
            d.d_year
        FROM tpcds.inventory i
        JOIN tpcds.date_dim d
          ON i.inv_date_sk = d.d_date_sk
        GROUP BY i.inv_item_sk, d.d_year
    ),

    -- 5️⃣ Web sales plus optional returns (joins WEB_SALES, WEB_PAGE, WEB_RETURNS)
    web_combined AS (
        SELECT
            ws.ws_bill_customer_sk,
            ws.ws_order_number,
            ws.ws_sales_price,
            ws.ws_net_profit,
            wp.wp_web_page_id,
            wp.wp_url,
            wr.wr_return_quantity,
            wr.wr_net_loss
        FROM tpcds.web_sales ws
        JOIN tpcds.web_page wp
          ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN tpcds.web_returns wr
          ON ws.ws_order_number = wr.wr_order_number
        WHERE ws.ws_sold_date_sk IN (
            SELECT d_date_sk FROM tpcds.date_dim WHERE d_year = 2001
        )
    ),

    -- 6️⃣ Promotion data (joins PROMOTION to DATE_DIM twice)
    promo_info AS (
        SELECT
            p.p_promo_sk,
            p.p_promo_id,
            p.p_discount_active,
            d_start.d_year AS start_year,
            d_end.d_year   AS end_year
        FROM tpcds.promotion p
        JOIN tpcds.date_dim d_start
          ON p.p_start_date_sk = d_start.d_date_sk
        JOIN tpcds.date_dim d_end
          ON p.p_end_date_sk = d_end.d_date_sk
        WHERE p.p_discount_active = 'Y'
    ),

    -- 7️⃣ Customers that appear in BOTH catalog and web sales (INTERSECT requirement)
    common_customers AS (
        SELECT c.c_customer_sk
        FROM tpcds.customer c
        JOIN agg_cs a
          ON a.cs_bill_customer_sk = c.c_customer_sk
        INTERSECT
        SELECT ws.ws_bill_customer_sk
        FROM tpcds.web_sales ws
        WHERE ws.ws_sold_date_sk IN (
            SELECT d_date_sk FROM tpcds.date_dim WHERE d_year = 2001
        )
    ),

    -- 8️⃣ Small dimension for a CROSS JOIN (rank levels)
    rank_levels AS (
        SELECT 1 AS level UNION ALL SELECT 2 UNION ALL SELECT 3
    )

SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.c_birth_country,
    cs.ca_state,
    cs.cd_gender,
    cs.total_sales,
    cs.total_profit,
    CASE
        WHEN cs.total_profit > 100000 THEN 'HIGH'
        WHEN cs.total_profit > 50000  THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY cs.ca_state ORDER BY cs.total_sales DESC) AS state_rank,
    sm.sm_type,
    cc.cc_name,
    p.p_promo_id,
    sf.s_store_name,
    sf.s_state               AS store_state,
    iw.qty_on_hand,
    wc.ws_sales_price,
    wc.ws_net_profit,
    rl.level                 AS rank_level
FROM cust_sales cs
JOIN tpcds.call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promo_info p
  ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN store_full sf
  ON cs.c_customer_sk = sf.sr_customer_sk
LEFT JOIN inv_year iw
  ON iw.d_year = sf.d_year               -- uses the year coming from STORE_FULL
LEFT JOIN web_combined wc
  ON cs.c_customer_sk = wc.ws_bill_customer_sk
CROSS JOIN rank_levels rl
WHERE
    cs.c_birth_country IN ('IRELAND', 'SWITZERLAND')
    AND cs.total_sales > 5000
    AND cs.c_customer_sk IN (SELECT c_customer_sk FROM common_customers)
    AND NOT EXISTS (
        SELECT 1 FROM tpcds.store_returns sr2
        WHERE sr2.sr_customer_sk = cs.c_customer_sk
    )
LIMIT 100
