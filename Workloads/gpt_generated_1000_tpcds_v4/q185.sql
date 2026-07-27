WITH
    cs_base AS (
        SELECT *
        FROM catalog_sales
    )
SELECT
    w.w_warehouse_name,
    d_sold.d_year,
    sum(cs.cs_ext_sales_price) AS total_sales,
    sum(cs.cs_net_profit) AS total_profit,
    count(distinct cs.cs_order_number) AS order_count,
    sum(sr.sr_net_loss) AS total_return_loss,
    avg(i.inv_quantity_on_hand) AS avg_inventory_on_hand
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN inventory i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
   AND i.inv_date_sk = d_sold.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d_sold.d_date_sk
JOIN customer_demographics cd_return
    ON sr.sr_cdemo_sk = cd_return.cd_demo_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_sold.d_date_sk
WHERE
    cd_bill.cd_credit_rating = 'Good'
    AND cd_bill.cd_gender = 'F'
    AND p.p_discount_active = 'Y'
    AND d_sold.d_year = 2001
    AND EXISTS (
        SELECT 1
        FROM web_site ws_filter
        WHERE ws_filter.web_company_name = 'able'
          AND ws_filter.web_open_date_sk = d_sold.d_date_sk
    )
GROUP BY
    w.w_warehouse_name,
    d_sold.d_year
ORDER BY
    total_sales DESC
LIMIT 100
