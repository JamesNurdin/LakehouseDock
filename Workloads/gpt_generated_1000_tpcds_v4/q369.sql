WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_ext_wholesale_cost,
        ss.ss_ext_tax,
        ss.ss_coupon_amt,
        ss.ss_net_paid,
        ss.ss_net_paid_inc_tax,
        ss.ss_net_profit,
        i.i_category,
        i.i_brand,
        s.s_store_name,
        s.s_division_name,
        ca.ca_state,
        c.c_birth_year,
        hd.hd_buy_potential,
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        sr.sr_return_amt,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_net_profit AS ws_net_profit,
        ws.ws_ext_tax AS ws_ext_tax,
        wp.wp_type,
        wr.wr_return_amt AS wr_return_amt
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    WHERE s.s_division_name = 'Unknown'
      AND ca.ca_state = 'CA'
      AND c.c_birth_year = 1985
      AND i.i_brand = 'BrandX'
      AND ib.ib_lower_bound >= 50000
      AND ss.ss_ext_sales_price > 1000
      AND ws.ws_net_profit > 0
      AND wp.wp_type = 'product'
)
SELECT
    s_store_name,
    i_category,
    hd_buy_potential,
    ib_lower_bound,
    SUM(ss_ext_sales_price) AS total_store_sales,
    SUM(ws_net_paid) AS total_web_sales,
    COUNT(DISTINCT ss_customer_sk) AS unique_customers,
    AVG(sr_return_amt) AS avg_store_return_amount,
    SUM(wr_return_amt) AS total_web_return_amount,
    MIN(ss_ext_discount_amt) AS min_store_discount,
    MAX(ws_ext_tax) AS max_web_tax
FROM base
GROUP BY
    s_store_name,
    i_category,
    hd_buy_potential,
    ib_lower_bound
ORDER BY total_store_sales DESC
LIMIT 100
