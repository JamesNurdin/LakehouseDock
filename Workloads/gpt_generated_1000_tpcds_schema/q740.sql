WITH sampled_inventory AS (
        SELECT inv_warehouse_sk, inv_date_sk, inv_quantity_on_hand
        FROM inventory TABLESAMPLE BERNOULLI (10)
    ),
    inv_agg AS (
        SELECT inv_warehouse_sk,
               inv_date_sk,
               SUM(inv_quantity_on_hand) AS total_qty
        FROM sampled_inventory
        GROUP BY inv_warehouse_sk, inv_date_sk
    ),
    sales_pre AS (
        SELECT ws.ws_warehouse_sk,
               ws.ws_promo_sk,
               ws.ws_sold_date_sk,
               cd.cd_gender,
               SUM(ws.ws_net_profit) AS sum_profit,
               SUM(ws.ws_quantity) AS sum_qty
        FROM web_sales ws
        JOIN customer_demographics cd
          ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        GROUP BY ws.ws_warehouse_sk,
                 ws.ws_promo_sk,
                 ws.ws_sold_date_sk,
                 cd.cd_gender
    ),
    joined_data AS (
        SELECT w.w_warehouse_id,
               p.p_promo_name,
               p.p_channel_email,
               d.d_year,
               sp.cd_gender,
               sp.sum_profit,
               sp.sum_qty,
               i.total_qty,
               CASE WHEN sp.sum_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
        FROM sales_pre sp
        JOIN inv_agg i
          ON sp.ws_warehouse_sk = i.inv_warehouse_sk
         AND sp.ws_sold_date_sk = i.inv_date_sk
        JOIN warehouse w
          ON sp.ws_warehouse_sk = w.w_warehouse_sk
        JOIN promotion p
          ON sp.ws_promo_sk = p.p_promo_sk
        JOIN date_dim d
          ON sp.ws_sold_date_sk = d.d_date_sk
    ),
    promo_warehouses_email AS (
        SELECT DISTINCT w.w_warehouse_id AS w_id
        FROM web_sales ws
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        WHERE p.p_channel_email = 'N'
    ),
    promo_warehouses_tv AS (
        SELECT DISTINCT w.w_warehouse_id AS w_id
        FROM web_sales ws
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        WHERE p.p_channel_tv = 'Y'
    ),
    email_not_tv_warehouses AS (
        SELECT w_id FROM promo_warehouses_email
        EXCEPT
        SELECT w_id FROM promo_warehouses_tv
    ),
    inventory_warehouses AS (
        SELECT DISTINCT w.w_warehouse_id AS w_id
        FROM sampled_inventory si
        JOIN warehouse w ON si.inv_warehouse_sk = w.w_warehouse_sk
    ),
    intersected_warehouses AS (
        SELECT w_id FROM email_not_tv_warehouses
        INTERSECT
        SELECT w_id FROM inventory_warehouses
    )
SELECT
    CASE WHEN GROUPING(jd.w_warehouse_id) = 0 THEN jd.w_warehouse_id END AS warehouse_id,
    CASE WHEN GROUPING(jd.p_promo_name) = 0 THEN jd.p_promo_name END AS promo_name,
    SUM(jd.sum_profit) AS total_profit,
    AVG(jd.total_qty) AS avg_inventory_qty,
    COUNT(*) AS row_count,
    SUM(CASE WHEN jd.profit_flag = 'Profitable' THEN 1 ELSE 0 END) AS profitable_rows
FROM joined_data jd
WHERE jd.d_year = 1999
  AND jd.cd_gender = 'M'
  AND jd.p_channel_email = 'N'
  AND jd.w_warehouse_id IN (SELECT w_id FROM intersected_warehouses)
GROUP BY GROUPING SETS (
    (jd.w_warehouse_id),
    (jd.p_promo_name),
    (jd.w_warehouse_id, jd.p_promo_name)
)
ORDER BY warehouse_id, promo_name
