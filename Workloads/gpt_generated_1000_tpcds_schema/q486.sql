WITH date_inventory AS (
    SELECT d.d_date_sk,
           d.d_year,
           inv.inv_item_sk,
           inv.inv_quantity_on_hand
    FROM   date_dim d
    FULL   OUTER JOIN inventory inv
           ON d.d_date_sk = inv.inv_date_sk
),
order_diff AS (
    SELECT cr_order_number FROM catalog_returns
    EXCEPT
    SELECT ws_order_number FROM web_sales
),
joined_all AS (
    SELECT d.d_date_sk,
           d.d_year,
           s.s_store_id,
           s.s_state,
           i.i_item_sk,
           i.i_current_price,
           ss.ss_net_profit,
           ws.ws_net_profit,
           cr.cr_order_number,
           cr.cr_net_loss,
           r.r_reason_desc,
           sm.sm_type,
           p.p_discount_active,
           ca.ca_city,
           cd.cd_gender,
           wp.wp_url
    FROM   date_inventory d
    JOIN   store_sales ss
           ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN   item i
           ON ss.ss_item_sk = i.i_item_sk
    JOIN   promotion p
           ON ss.ss_promo_sk = p.p_promo_sk
    JOIN   customer c
           ON ss.ss_customer_sk = c.c_customer_sk
    JOIN   customer_demographics cd
           ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN   customer_address ca
           ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN   store s
           ON ss.ss_store_sk = s.s_store_sk
    JOIN   catalog_returns cr
           ON cr.cr_returned_date_sk = d.d_date_sk
          AND cr.cr_item_sk = i.i_item_sk
          AND cr.cr_refunded_customer_sk = c.c_customer_sk
          AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
          AND cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN   ship_mode sm
           ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN   reason r
           ON cr.cr_reason_sk = r.r_reason_sk
    JOIN   web_sales ws
           ON ws.ws_sold_date_sk = d.d_date_sk
          AND ws.ws_item_sk = i.i_item_sk
          AND ws.ws_bill_customer_sk = c.c_customer_sk
          AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
          AND ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN   web_page wp
           ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE  i.i_current_price > 100
      AND d.d_year BETWEEN 1999 AND 2001
      AND s.s_state = 'CA'
      AND cd.cd_gender = 'M'
      AND r.r_reason_desc LIKE '%size%'
      AND cr.cr_order_number IN (SELECT cr_order_number FROM order_diff)
),
store_agg AS (
    SELECT s_store_id,
           d_year,
           SUM(ss_net_profit) AS profit
    FROM   joined_all
    GROUP BY s_store_id, d_year
),
web_agg AS (
    SELECT s_store_id,
           d_year,
           SUM(ws_net_profit) AS profit
    FROM   joined_all
    GROUP BY s_store_id, d_year
),
union_agg AS (
    SELECT s_store_id, d_year, profit FROM store_agg
    UNION
    SELECT s_store_id, d_year, profit FROM web_agg
),
final_agg AS (
    SELECT s_store_id,
           d_year,
           SUM(profit) AS total_profit
    FROM   union_agg
    GROUP BY s_store_id, d_year
),
ranked AS (
    SELECT s_store_id,
           d_year,
           total_profit,
           ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS rn
    FROM   final_agg
    WHERE  s_store_id IN (SELECT s_store_id FROM store WHERE s_state = 'CA')
)
SELECT s_store_id,
       d_year,
       total_profit
FROM   ranked
WHERE  rn <= 3
ORDER BY d_year,
         total_profit DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
