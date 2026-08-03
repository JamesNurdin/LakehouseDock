WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_ext_discount_amt,
        ss.ss_ext_sales_price,
        ss.ss_coupon_amt,
        ss.ss_ticket_number,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_item_id,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        s.s_store_name,
        s.s_state,
        ca.ca_city
    FROM store_sales ss
    JOIN date_dim d            ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i                ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c            ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s               ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca   ON ss.ss_addr_sk = ca.ca_address_sk
)
SELECT
    s_store_name,
    i_category,
    d_year,
    d_month_seq,
    ca_city,
    SUM(ss_ext_sales_price)                     AS total_store_sales,
    SUM(cs.cs_ext_sales_price)                  AS total_catalog_sales,
    COUNT(DISTINCT ss_ticket_number)            AS store_orders,
    AVG(ss_coupon_amt)                          AS avg_coupon_amount,
    SUM(cr.cr_return_amount)                    AS total_catalog_returns,
    SUM(wr.wr_return_amt)                       AS total_web_returns,
    AVG(ib.ib_upper_bound)                      AS avg_income_upper
FROM base
LEFT JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = base.ss_sold_date_sk
   AND cs.cs_item_sk      = base.ss_item_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = base.ss_sold_date_sk
   AND cr.cr_item_sk          = base.ss_item_sk
FULL OUTER JOIN web_returns wr
    ON wr.wr_returned_date_sk = base.ss_sold_date_sk
   AND wr.wr_item_sk          = base.ss_item_sk
LEFT JOIN web_page wp
    ON wp.wp_creation_date_sk = base.ss_sold_date_sk
LEFT JOIN call_center cc
    ON cc.cc_closed_date_sk = base.ss_sold_date_sk
LEFT JOIN income_band ib
    ON ib.ib_income_band_sk = base.hd_income_band_sk
WHERE
    s_state = 'TX'
    AND i_category = 'Electronics'
    AND d_year = 2002
    AND hd_buy_potential = '501-1000'
    AND ss_quantity > 5
    AND ss_ext_discount_amt < 500
    AND EXISTS (
        SELECT 1 FROM web_returns wr2
        WHERE wr2.wr_refunded_customer_sk = base.ss_customer_sk
          AND wr2.wr_returned_date_sk = base.ss_sold_date_sk
    )
GROUP BY
    s_store_name,
    i_category,
    d_year,
    d_month_seq,
    ca_city
ORDER BY total_store_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
