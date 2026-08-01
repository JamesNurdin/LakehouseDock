WITH date_filtered AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 2001
      AND d_month_seq = 11
      AND d_holiday = 'N'
)
SELECT
    df.d_year,
    df.d_month_seq,
    s.s_store_name,
    we.web_name,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(sr.sr_net_loss) AS total_store_loss,
    SUM(wr.wr_net_loss) AS total_web_loss,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
    CASE WHEN SUM(cs.cs_net_paid) > 1000000 THEN 'HIGH' ELSE 'LOW' END AS revenue_category,
    (SELECT MAX(d_date) FROM date_dim WHERE d_year = 2001) AS max_date_in_year
FROM date_filtered df
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = df.d_date_sk
JOIN customer_address ca
    ON ca.ca_address_sk = cs.cs_bill_addr_sk
JOIN customer_demographics cd
    ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
JOIN household_demographics hd
    ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = df.d_date_sk
JOIN store s
    ON s.s_store_sk = sr.sr_store_sk
JOIN reason r
    ON r.r_reason_sk = sr.sr_reason_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = df.d_date_sk
JOIN web_page wp
    ON wp.wp_web_page_sk = wr.wr_web_page_sk
JOIN web_site we
    ON we.web_open_date_sk = df.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = df.d_date_sk
WHERE ca.ca_state = 'CA'
  AND hd.hd_vehicle_count >= 2
  AND r.r_reason_desc LIKE '%product%'
  AND we.web_name = 'example.com'
GROUP BY
    df.d_year,
    df.d_month_seq,
    s.s_store_name,
    we.web_name
ORDER BY total_net_paid DESC
LIMIT 100
