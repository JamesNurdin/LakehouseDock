WITH sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_quantity,
        d_sold.d_year,
        ca.ca_state,
        ca.ca_address_sk,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        w.w_warehouse_name,
        wp.wp_type,
        wsit.web_name,
        cc.cc_state
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN tpcds.customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN tpcds.call_center cc
        ON cc.cc_open_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND ca.ca_state = 'CA'
      AND ib.ib_lower_bound >= 50000
      AND ws.ws_order_number IN (
          SELECT DISTINCT sr.sr_ticket_number
          FROM tpcds.store_returns sr
          JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
          WHERE r.r_reason_desc = 'Damaged'
      )
),
agg_sales AS (
    SELECT
        d_year,
        ca_state,
        hd_buy_potential,
        w_warehouse_name,
        web_name,
        cc_state,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_ext_discount_amt) AS total_discount,
        AVG(ws_quantity) AS avg_quantity,
        COUNT(DISTINCT ws_order_number) AS distinct_orders,
        COUNT(DISTINCT ca_address_sk) AS distinct_customers,
        (
            SELECT COALESCE(SUM(sr.sr_net_loss), 0)
            FROM tpcds.store_returns sr
            JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
            JOIN tpcds.date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
            WHERE r.r_reason_desc = 'Damaged'
              AND d_ret.d_year = d_year
        ) AS total_return_loss
    FROM sales_data
    GROUP BY
        d_year,
        ca_state,
        hd_buy_potential,
        w_warehouse_name,
        web_name,
        cc_state
    HAVING SUM(ws_net_profit) > 100000
)
SELECT
    d_year,
    ca_state,
    hd_buy_potential,
    w_warehouse_name,
    web_name,
    cc_state,
    total_profit,
    total_discount,
    avg_quantity,
    distinct_orders,
    distinct_customers,
    total_return_loss,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM agg_sales
ORDER BY profit_rank
LIMIT 100
