WITH sales_agg AS (
    SELECT
        s.s_store_name,
        i.i_item_id,
        i.i_item_sk,
        SUM(ss.ss_quantity) AS total_qty,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE WHEN SUM(ss.ss_quantity) > 100 THEN 'High Volume' ELSE 'Normal Volume' END AS volume_category,
        MIN(d.d_date) AS first_sale_date
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand1'
      AND cd.cd_credit_rating = 'Good'
      AND p.p_discount_active = 'Y'
      AND s.s_state = 'CA'
      AND s.s_gmt_offset BETWEEN -8 AND -5
    GROUP BY s.s_store_name, i.i_item_id, i.i_item_sk
)
SELECT
    sa.s_store_name,
    sa.i_item_id,
    sa.total_qty,
    sa.total_profit,
    sa.volume_category,
    (SELECT MAX(p2.p_cost) FROM promotion p2 WHERE p2.p_item_sk = sa.i_item_sk) AS max_promo_cost,
    AVG(sa.total_profit) OVER (PARTITION BY sa.volume_category) AS avg_profit_by_volume
FROM sales_agg sa
JOIN catalog_returns cr ON cr.cr_item_sk = sa.i_item_sk
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv ON inv.inv_item_sk = sa.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_site ws ON ws.web_open_date_sk = d_ret.d_date_sk
WHERE cp.cp_department = 'Electronics'
  AND sm.sm_type = 'EXPRESS'
  AND w.w_state = 'CA'
  AND ws.web_state = 'CA'
  AND d_ret.d_month_seq BETWEEN 1200 AND 1300
  AND inv.inv_quantity_on_hand > 0
ORDER BY sa.total_profit DESC
LIMIT 100
