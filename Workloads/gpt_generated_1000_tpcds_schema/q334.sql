WITH avg_item_price AS (
        SELECT AVG(i_current_price) AS avg_price
        FROM tpcds.item
        WHERE i_category = 'Electronics'
    ),
    sampled_inventory AS (
        SELECT *
        FROM tpcds.inventory TABLESAMPLE BERNOULLI (10)
    )
SELECT
    d.d_year,
    s.s_state,
    i.i_category,
    u.word,
    SUM(COALESCE(cs.cs_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) - COALESCE(sr.sr_net_loss, 0)) AS total_profit,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(COALESCE(cs.cs_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) - COALESCE(sr.sr_net_loss, 0)) DESC) AS profit_rank,
    (SELECT avg_price FROM avg_item_price) AS overall_avg_item_price
FROM tpcds.catalog_sales cs
FULL OUTER JOIN tpcds.catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN tpcds.date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
INNER JOIN tpcds.time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
INNER JOIN tpcds.customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
INNER JOIN tpcds.customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
INNER JOIN tpcds.household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
INNER JOIN tpcds.item i
    ON cs.cs_item_sk = i.i_item_sk
INNER JOIN tpcds.promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
INNER JOIN tpcds.warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
INNER JOIN sampled_inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
   AND inv.inv_date_sk = d.d_date_sk
INNER JOIN tpcds.store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_return_time_sk = t.t_time_sk
INNER JOIN tpcds.store s
    ON sr.sr_store_sk = s.s_store_sk
INNER JOIN tpcds.web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_sold_time_sk = t.t_time_sk
INNER JOIN tpcds.web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
-- Unnest words from the catalog page description
LEFT JOIN UNNEST(split(cp.cp_description, ' ')) AS u(word) ON true
WHERE d.d_year = 2001
  AND i.i_brand = 'Brand#23'
  AND s.s_state = 'CA'
  AND EXISTS (
        SELECT 1 FROM tpcds.promotion p2
        WHERE p2.p_discount_active = 'Y' AND p2.p_promo_sk = p.p_promo_sk
    )
GROUP BY CUBE (d.d_year, s.s_state, i.i_category, u.word)
ORDER BY total_profit DESC
LIMIT 100
