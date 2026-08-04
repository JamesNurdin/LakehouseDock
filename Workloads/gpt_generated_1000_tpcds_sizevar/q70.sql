WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        d.d_year,
        i.i_brand,
        i.i_category,
        p.p_promo_name,
        sm.sm_carrier,
        w.w_state,
        ws.ws_quantity AS ws_quantity
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
     AND ws.ws_sold_date_sk = d.d_date_sk
)
SELECT
    base.cs_order_number,
    base.cs_item_sk,
    base.i_brand,
    base.i_category,
    base.w_state,
    base.sm_carrier,
    base.p_promo_name,
    base.d_year,
    SUM(base.cs_quantity) AS total_quantity,
    SUM(base.cs_net_paid) AS total_net_paid,
    SUM(base.cr_return_amount) AS total_return_amount,
    (SELECT SUM(ws2.ws_quantity)
       FROM web_sales ws2
      WHERE ws2.ws_item_sk = base.cs_item_sk) AS total_ws_quantity,
    CASE WHEN SUM(base.cs_net_paid) > 10000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_category,
    RANK() OVER (PARTITION BY base.d_year ORDER BY SUM(base.cs_net_paid) DESC) AS yearly_net_paid_rank
FROM base
WHERE base.d_year BETWEEN 2000 AND 2002
  AND base.w_state IN ('NY', 'GA')
  AND base.i_brand = 'Brand#12'
  AND base.sm_carrier = 'UPS'
  AND base.p_promo_name LIKE '%Discount%'
GROUP BY
    base.cs_order_number,
    base.cs_item_sk,
    base.i_brand,
    base.i_category,
    base.w_state,
    base.sm_carrier,
    base.p_promo_name,
    base.d_year
ORDER BY yearly_net_paid_rank ASC, total_net_paid DESC
LIMIT 100
