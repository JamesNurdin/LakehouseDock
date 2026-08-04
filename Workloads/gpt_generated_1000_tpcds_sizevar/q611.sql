WITH
    /* Pre‑aggregate store sales (sampled) */
    store_sales_agg AS (
        SELECT
            ss_store_sk,
            ss_sold_date_sk,
            SUM(ss_ext_sales_price) AS total_store_sales,
            COUNT(*) AS store_sales_cnt
        FROM store_sales
        TABLESAMPLE BERNOULLI (10)
        GROUP BY ss_store_sk, ss_sold_date_sk
    ),
    /* Orders that have never been returned */
    non_returned_orders AS (
        SELECT ws_order_number
        FROM web_sales
        EXCEPT
        SELECT wr_order_number
        FROM web_returns
    ),
    /* Total sales per state (derived from the first CTE) */
    state_sales AS (
        SELECT
            s.s_state,
            SUM(agg.total_store_sales) AS state_total_sales
        FROM store_sales_agg agg
        JOIN store s ON agg.ss_store_sk = s.s_store_sk
        GROUP BY s.s_state
    )
SELECT
    s.s_store_id,
    d.d_date,
    CASE WHEN agg.total_store_sales > 1000 THEN 'High' ELSE 'Low' END AS sales_volume_category,
    c.c_customer_id,
    cd.cd_credit_rating,
    hd.hd_buy_potential,
    i.i_item_id,
    i.i_current_price,
    ws.ws_quantity,
    ws.ws_net_paid,
    r.r_reason_desc,
    lt.max_link_count,
    agg.total_store_sales,
    agg.store_sales_cnt,
    (SELECT AVG(i2.i_current_price) FROM item i2) AS avg_price_all_items,
    ss_state.state_total_sales
FROM store_sales_agg agg
JOIN store s
    ON agg.ss_store_sk = s.s_store_sk
JOIN date_dim d
    ON agg.ss_sold_date_sk = d.d_date_sk
JOIN store_sales ss
    ON ss.ss_store_sk = agg.ss_store_sk
   AND ss.ss_sold_date_sk = agg.ss_sold_date_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_item_sk = i.i_item_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN LATERAL (
        SELECT MAX(wp2.wp_link_count) AS max_link_count
        FROM web_page wp2
        WHERE wp2.wp_web_page_sk = wp.wp_web_page_sk
) lt ON true
JOIN state_sales ss_state
    ON s.s_state = ss_state.s_state
WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND s.s_state = 'TX'
  AND ca.ca_country = 'United States'
  AND hd.hd_income_band_sk > 3
  AND i.i_brand = 'Brand#12'
  AND t.t_hour BETWEEN 9 AND 17
  AND cd.cd_credit_rating = 'Good'
  AND ws.ws_order_number IN (SELECT ws_order_number FROM non_returned_orders)
  AND ss_state.state_total_sales > 10000
ORDER BY agg.total_store_sales DESC
LIMIT 100
