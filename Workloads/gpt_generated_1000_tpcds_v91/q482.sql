WITH raw_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        -- fetch catalog page number via a scalar subquery (semi‑join)
        (SELECT cp.cp_catalog_number FROM catalog_page cp
         WHERE cp.cp_catalog_page_sk = cs.cs_catalog_page_sk) AS cp_catalog_number,
        cc.cc_name,
        split(cc.cc_name, ' ') AS name_words,
        p.p_discount_active,
        sm.sm_carrier,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_country,
        hd.hd_demo_sk,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_paid_inc_ship,
        ws.ws_order_number,
        wr.wr_return_quantity
    FROM catalog_sales cs
    INNER JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
                             AND ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
                           AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
                           AND ws.ws_warehouse_sk = w.w_warehouse_sk
                           AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                             AND wr.wr_item_sk = ws.ws_item_sk
    WHERE w.w_country = 'United States'
      AND sm.sm_carrier = 'HARMSTORF'
      AND cs.cs_quantity > 5
      AND ws.ws_net_paid_inc_ship > 1000
      AND p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1 FROM catalog_page cp_chk
          WHERE cp_chk.cp_catalog_page_sk = cs.cs_catalog_page_sk
      )
),

unnested_names AS (
    SELECT
        rd.*,
        word
    FROM raw_data rd
    CROSS JOIN UNNEST(rd.name_words) AS t(word)
),

agg AS (
    SELECT
        w_warehouse_sk,
        w_warehouse_name,
        sm_carrier,
        COUNT(DISTINCT cs_sold_date_sk) AS distinct_sold_days,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        SUM(ws_net_paid_inc_ship) AS total_ws_paid,
        MAX(ws_net_paid_inc_ship) AS max_ws_paid,
        COUNT(*) FILTER (WHERE wr_return_quantity IS NOT NULL) AS return_count,
        SUM(cs_net_profit) / NULLIF(COUNT(DISTINCT cs_sold_date_sk), 0) AS profit_per_day
    FROM unnested_names
    GROUP BY w_warehouse_sk, w_warehouse_name, sm_carrier
    HAVING SUM(cs_ext_sales_price) > 10000
       AND SUM(cs_net_profit) > 0
       AND NOT EXISTS (
           SELECT 1
           FROM web_returns wr2
           JOIN web_sales ws2 ON wr2.wr_order_number = ws2.ws_order_number
                              AND wr2.wr_item_sk = ws2.ws_item_sk
           WHERE ws2.ws_warehouse_sk = w_warehouse_sk
       )
)

SELECT
    a.w_warehouse_name,
    a.sm_carrier,
    a.distinct_sold_days,
    a.total_sales,
    a.total_profit,
    a.total_ws_paid,
    a.max_ws_paid,
    a.profit_per_day,
    ROW_NUMBER() OVER (ORDER BY a.total_profit DESC) AS profit_rank,
    (SELECT AVG(ws3.ws_quantity)
     FROM web_sales ws3
     WHERE ws3.ws_warehouse_sk = a.w_warehouse_sk) AS avg_ws_quantity,
    (SELECT AVG(LENGTH(u.word))
     FROM unnested_names u
     WHERE u.w_warehouse_sk = a.w_warehouse_sk) AS avg_word_length
FROM agg a
ORDER BY profit_rank
LIMIT 30
