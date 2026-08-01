WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        d_ss.d_year AS year,
        ss.ss_ext_sales_price AS store_sales_price,
        ss.ss_net_profit AS store_net_profit,
        sr.sr_return_amt AS store_return_amt,
        sr.sr_return_quantity AS store_return_qty,
        c.c_customer_sk,
        cd.cd_credit_rating,
        cd.cd_education_status,
        hd.hd_vehicle_count,
        ca.ca_state AS cust_state,
        p_ss.p_discount_active,
        p_ss.p_cost,
        ws.ws_sold_date_sk,
        d_ws_sold.d_year AS ws_year,
        ws.ws_ext_sales_price AS web_sales_price,
        ws.ws_net_profit AS web_net_profit,
        wr.wr_return_amt AS web_return_amt,
        wr.wr_return_quantity AS web_return_qty,
        w.w_state AS w_state,
        ib.ib_upper_bound,
        inv.inv_quantity_on_hand,
        web_site.web_name,
        web_site.web_manager,
        wp.wp_type,
        ws.ws_order_number,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ws.ws_item_sk
    FROM store_sales ss
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
    JOIN customer_demographics cd2 ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
    JOIN customer_address ca2 ON ws.ws_bill_addr_sk = ca2.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ON ws.ws_web_site_sk = web_site.web_site_sk
    JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d_wr_returned ON wr.wr_returned_date_sk = d_wr_returned.d_date_sk
    JOIN household_demographics hd_hb ON ws.ws_ship_hdemo_sk = hd_hb.hd_demo_sk
    JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN income_band ib_ws ON hd2.hd_income_band_sk = ib_ws.ib_income_band_sk
    WHERE d_ss.d_year = 2001
      AND cd.cd_education_status = 'Advanced Degree'
      AND hd.hd_vehicle_count >= 2
      AND p_ss.p_discount_active = 'Y'
      AND inv.inv_quantity_on_hand > 0
      AND w.w_state = 'CA'
      AND web_site.web_manager = 'Jimmy Pope'
      AND EXISTS (
        SELECT 1
        FROM web_returns wr_check
        WHERE wr_check.wr_order_number = ws.ws_order_number
          AND wr_check.wr_return_quantity > 0
      )
),
agg AS (
    SELECT
        year,
        w_state,
        web_name,
        CASE WHEN cd_credit_rating = 'Good' THEN 'LowRisk' ELSE 'Other' END AS credit_category,
        SUM(store_sales_price) AS total_store_sales,
        SUM(store_net_profit) AS total_store_profit,
        SUM(web_sales_price) AS total_web_sales,
        SUM(web_net_profit) AS total_web_profit,
        SUM(store_return_amt) + SUM(web_return_amt) AS total_return_amount,
        SUM(inv_quantity_on_hand) AS total_inventory_qty,
        (SUM(store_sales_price) + SUM(web_sales_price)) AS total_combined_sales,
        (SUM(store_net_profit) + SUM(web_net_profit)) AS total_combined_profit
    FROM base
    GROUP BY
        year,
        w_state,
        web_name,
        CASE WHEN cd_credit_rating = 'Good' THEN 'LowRisk' ELSE 'Other' END
)
SELECT
    year,
    w_state,
    web_name,
    credit_category,
    total_store_sales,
    total_store_profit,
    total_web_sales,
    total_web_profit,
    total_return_amount,
    total_inventory_qty,
    total_combined_sales,
    RANK() OVER (ORDER BY total_combined_profit DESC) AS profit_rank,
    SUM(total_combined_sales) OVER (
        PARTITION BY w_state ORDER BY year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales_by_state
FROM agg
ORDER BY profit_rank
LIMIT 100
