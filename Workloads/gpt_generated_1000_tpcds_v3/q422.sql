WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk, inv_warehouse_sk
),
ws_agg AS (
    SELECT ws.ws_item_sk,
           ws.ws_warehouse_sk,
           ws.ws_web_site_sk,
           t.t_shift,
           ws_site.web_name,
           SUM(ws.ws_ext_sales_price) AS total_ws_sales,
           SUM(ws.ws_net_paid) AS total_ws_net_paid,
           SUM(ws.ws_net_profit) AS total_ws_profit
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE t.t_shift = 'first'
      AND ws.ws_quantity > 0
      AND ws_site.web_name = 'Online'
    GROUP BY ws.ws_item_sk, ws.ws_warehouse_sk, ws.ws_web_site_sk, t.t_shift, ws_site.web_name
),
sr_agg AS (
    SELECT sr.sr_item_sk,
           sr.sr_store_sk,
           sr.sr_reason_sk,
           sr.sr_cdemo_sk,
           sr.sr_hdemo_sk,
           SUM(sr.sr_return_amt) AS total_return_amt,
           SUM(sr.sr_net_loss) AS total_net_loss,
           COUNT(*) AS return_cnt
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 0
    GROUP BY sr.sr_item_sk, sr.sr_store_sk, sr.sr_reason_sk, sr.sr_cdemo_sk, sr.sr_hdemo_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    i.i_current_price,
    i.i_color,
    w.w_warehouse_name,
    s.s_store_name,
    s.s_state,
    ws_agg.t_shift,
    ws_agg.web_name AS web_site_name,
    cd_ret.cd_gender,
    cd_ret.cd_marital_status,
    hd_ret.hd_buy_potential,
    r.r_reason_desc,
    inv_agg.total_qty_on_hand,
    COALESCE(ws_agg.total_ws_sales, 0) AS total_web_sales,
    COALESCE(sr_agg.total_return_amt, 0) AS total_return_amount,
    (COALESCE(ws_agg.total_ws_sales, 0) - COALESCE(sr_agg.total_return_amt, 0)) AS net_sales_amount,
    ROW_NUMBER() OVER (
        PARTITION BY i.i_category
        ORDER BY (COALESCE(ws_agg.total_ws_sales, 0) - COALESCE(sr_agg.total_return_amt, 0)) DESC
    ) AS category_rank,
    CASE
        WHEN (COALESCE(ws_agg.total_ws_sales, 0) - COALESCE(sr_agg.total_return_amt, 0)) > 100000 THEN 'High'
        ELSE 'Medium'
    END AS sales_volume_category
FROM inv_agg
JOIN item i ON inv_agg.inv_item_sk = i.i_item_sk
JOIN warehouse w ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN ws_agg ON i.i_item_sk = ws_agg.ws_item_sk AND w.w_warehouse_sk = ws_agg.ws_warehouse_sk
LEFT JOIN sr_agg ON i.i_item_sk = sr_agg.sr_item_sk
LEFT JOIN store s ON sr_agg.sr_store_sk = s.s_store_sk
LEFT JOIN reason r ON sr_agg.sr_reason_sk = r.r_reason_sk
LEFT JOIN customer_demographics cd_ret ON sr_agg.sr_cdemo_sk = cd_ret.cd_demo_sk
LEFT JOIN household_demographics hd_ret ON sr_agg.sr_hdemo_sk = hd_ret.hd_demo_sk
WHERE i.i_current_price > 100
  AND i.i_color = 'Red'
  AND s.s_state = 'CA'
  AND cd_ret.cd_marital_status = 'M'
  AND hd_ret.hd_buy_potential = '501-1000'
ORDER BY net_sales_amount DESC, category_rank ASC
