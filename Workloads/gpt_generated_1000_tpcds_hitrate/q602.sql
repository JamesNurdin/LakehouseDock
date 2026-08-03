WITH wr_base AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_item_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_returning_customer_sk,
        wr.wr_web_page_sk,
        wr.wr_reason_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        t.t_hour,
        t.t_minute,
        t.t_sub_shift,
        r.r_reason_desc,
        ca.ca_county,
        wp.wp_type,
        c.c_first_name,
        c.c_last_name
    FROM web_returns wr
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE t.t_sub_shift = 'morning'
      AND r.r_reason_desc LIKE '%damaged%'
      AND wp.wp_type = 'article'
      AND ca.ca_county = 'Washington County'
),
agg AS (
    SELECT
        ca_county,
        c_first_name,
        c_last_name,
        r_reason_desc,
        SUM(wr_return_quantity) AS total_quantity,
        SUM(wr_net_loss) AS total_loss,
        AVG(wr_return_amt) AS avg_return_amount,
        DENSE_RANK() OVER (PARTITION BY ca_county ORDER BY SUM(wr_net_loss) DESC) AS county_loss_rank
    FROM wr_base
    WHERE EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_refunded_customer_sk = wr_base.wr_refunded_customer_sk
          AND cr.cr_returned_date_sk = wr_base.wr_returned_date_sk
    )
    GROUP BY ca_county, c_first_name, c_last_name, r_reason_desc
    HAVING SUM(wr_net_loss) > 1000
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_loss DESC) AS global_row_num,
    ca_county,
    c_first_name,
    c_last_name,
    r_reason_desc,
    total_quantity,
    total_loss,
    avg_return_amount,
    county_loss_rank
FROM agg
WHERE county_loss_rank <= 3
ORDER BY total_loss DESC
LIMIT 100
