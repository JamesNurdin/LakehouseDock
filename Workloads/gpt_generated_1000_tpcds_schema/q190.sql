WITH
    ws_detail AS (
        SELECT
            ws.ws_order_number,
            d_sold.d_year,
            sm.sm_carrier,
            p.p_promo_name,
            ws.ws_sales_price,
            ws.ws_net_profit,
            c_bill.c_customer_id,
            cd_bill.cd_credit_rating,
            hd_bill.hd_buy_potential,
            t_sold.t_hour
        FROM web_sales ws
        JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
        JOIN time_dim t_sold ON ws.ws_sold_time_sk = t_sold.t_time_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
        JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
        WHERE d_sold.d_year BETWEEN 2001 AND 2002
          AND sm.sm_carrier = 'PRIVATECARRIER'
          AND p.p_discount_active = 'Y'
          AND w.w_state = 'CA'
          AND cd_bill.cd_credit_rating = 'Good'
          AND t_sold.t_hour BETWEEN 9 AND 17
    ),
    ss_detail AS (
        SELECT
            ss.ss_ticket_number,
            d_sold.d_year,
            ss.ss_sales_price,
            ss.ss_net_profit,
            s.s_store_name,
            s.s_tax_percentage,
            ca.ca_state,
            cd.cd_credit_rating,
            hd.hd_income_band_sk,
            ib.ib_lower_bound,
            ib.ib_upper_bound
        FROM store_sales ss
        JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE d_sold.d_year = 2001
          AND s.s_tax_percentage > 0.05
          AND ca.ca_country = 'United States'
          AND cd.cd_purchase_estimate > 5000
          AND ib.ib_upper_bound >= 75000
    ),
    catalog_ret AS (
        SELECT
            cr.cr_order_number,
            cr.cr_return_amount,
            cp.cp_department,
            sm2.sm_carrier AS return_carrier,
            w2.w_warehouse_name
        FROM catalog_returns cr
        JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm2 ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
        JOIN warehouse w2 ON cr.cr_warehouse_sk = w2.w_warehouse_sk
        WHERE d_ret.d_year = 2001
          AND cp.cp_type = 'PROMO'
          AND cr.cr_return_amount > 1000
    ),
    web_ret AS (
        SELECT
            wr.wr_order_number,
            wr.wr_return_amt,
            wr.wr_net_loss
        FROM web_returns wr
        JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
        WHERE d_wr.d_year = 2001
          AND wr.wr_return_amt > 500
    )
SELECT
    ws.ws_order_number,
    ws.d_year,
    ws.sm_carrier,
    ws.p_promo_name,
    SUM(ws.ws_sales_price) AS total_sales_price,
    AVG(ws.ws_net_profit) AS avg_net_profit,
    COUNT(DISTINCT ws.c_customer_id) AS distinct_customers
FROM ws_detail ws
WHERE ws.ws_order_number IN (
        SELECT diff.ws_id
        FROM (
            SELECT ws.ws_order_number AS ws_id
            FROM ws_detail ws
            EXCEPT
            SELECT ss.ss_ticket_number AS ws_id
            FROM ss_detail ss
        ) diff
    )
  AND EXISTS (
        SELECT 1
        FROM catalog_ret cr
        WHERE cr.cr_order_number = ws.ws_order_number
          AND cr.cr_return_amount > 2000
    )
  AND EXISTS (
        SELECT 1
        FROM web_ret wr
        WHERE wr.wr_order_number = ws.ws_order_number
          AND wr.wr_net_loss > 1000
    )
GROUP BY
    ws.ws_order_number,
    ws.d_year,
    ws.sm_carrier,
    ws.p_promo_name
HAVING SUM(ws.ws_sales_price) > 10000
ORDER BY total_sales_price DESC
LIMIT 100
