WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_paid,
        ss.ss_ext_discount_amt,
        ss.ss_ext_sales_price
    FROM store_sales ss
    WHERE ss.ss_sales_price > 50
      AND ss.ss_quantity >= 1
)
SELECT *
FROM (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        i.i_item_id,
        i.i_product_name,
        r.r_reason_desc,
        wp.wp_type,
        SUM(fs.ss_net_paid) AS total_net_paid,
        AVG(fs.ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT fs.ss_ticket_number) AS distinct_tickets,
        MIN(fs.ss_ext_discount_amt) AS min_discount,
        MAX(fs.ss_ext_discount_amt) AS max_discount,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(fs.ss_net_paid) DESC) AS purchase_rank
    FROM filtered_sales fs
    JOIN customer c
      ON fs.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON fs.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
      ON fs.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN item i
      ON fs.ss_item_sk = i.i_item_sk
    JOIN promotion p
      ON fs.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t
      ON fs.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN web_returns wr
      ON wr.wr_item_sk = fs.ss_item_sk
         AND wr.wr_returned_date_sk = fs.ss_sold_date_sk
    LEFT JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        hd.hd_income_band_sk = 16
        AND hd.hd_buy_potential = '>10000'
        AND p.p_discount_active = 'Y'
        AND t.t_hour BETWEEN 9 AND 17
        AND NOT EXISTS (
            SELECT 1 FROM web_returns wr2
            WHERE wr2.wr_item_sk = fs.ss_item_sk
              AND wr2.wr_returned_date_sk = fs.ss_sold_date_sk
        )
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        i.i_item_id,
        i.i_product_name,
        r.r_reason_desc,
        wp.wp_type,
        c.c_customer_sk
) sub
ORDER BY total_net_paid DESC
LIMIT 100
