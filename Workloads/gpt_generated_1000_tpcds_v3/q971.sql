WITH base_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_wholesale_cost,
        ss.ss_list_price,
        ss.ss_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_ext_sales_price,
        ss.ss_ext_wholesale_cost,
        ss.ss_ext_list_price,
        ss.ss_ext_tax,
        ss.ss_coupon_amt,
        ss.ss_net_paid,
        ss.ss_net_paid_inc_tax,
        ss.ss_net_profit,
        d.d_date_sk,
        d.d_year,
        d.d_fy_week_seq,
        d.d_following_holiday,
        ca_sales.ca_address_sk AS ca_sales_address_sk,
        ca_sales.ca_county,
        ca_sales.ca_state,
        ca_sales.ca_city,
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_state AS cc_state,
        cc.cc_street_type,
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_type
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca_sales
        ON ss.ss_addr_sk = ca_sales.ca_address_sk
    LEFT JOIN call_center cc
        ON cc.cc_open_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_fy_week_seq = 15
      AND d.d_following_holiday = 'N'
      AND ca_sales.ca_county = 'Maricopa County'
      AND cc.cc_state = 'CA'
      AND cc.cc_street_type = 'Boulevard'
      AND cp.cp_department = 'Sports'
)
SELECT
    bs.cc_name,
    bs.cp_department,
    bs.d_year,
    bs.ca_state,
    SUM(bs.ss_net_paid) AS total_net_paid,
    SUM(bs.ss_net_paid_inc_tax) AS total_net_paid_inc_tax,
    COUNT(DISTINCT bs.ss_ticket_number) AS distinct_tickets,
    SUM(CASE WHEN sr.sr_return_quantity > 0 THEN sr.sr_return_amt ELSE 0 END) AS total_store_return_amt,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss,
    CASE WHEN SUM(bs.ss_net_paid) > 100000 THEN 'Big' ELSE 'Small' END AS sales_category
FROM base_sales bs
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = bs.ss_item_sk
   AND sr.sr_ticket_number = bs.ss_ticket_number
   AND sr.sr_returned_date_sk = bs.d_date_sk
LEFT JOIN customer_address ca_returns
    ON sr.sr_addr_sk = ca_returns.ca_address_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = bs.d_date_sk
LEFT JOIN customer_address ca_refunded
    ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
LEFT JOIN customer_address ca_returning
    ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
WHERE ca_returns.ca_state IS NOT NULL
GROUP BY bs.cc_name, bs.cp_department, bs.d_year, bs.ca_state
HAVING SUM(bs.ss_net_paid) > 50000
ORDER BY total_net_paid DESC
LIMIT 100
