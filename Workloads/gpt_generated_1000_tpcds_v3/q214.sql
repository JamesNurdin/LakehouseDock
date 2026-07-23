WITH filtered_dates AS (
    SELECT d_date_sk, d_year, d_date
    FROM date_dim
    WHERE d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
)
SELECT
    d_year,
    cd_gender,
    ca_city,
    loss_category,
    SUM(net_loss) AS total_net_loss
FROM (
    SELECT
        d.d_year,
        cd.cd_gender,
        ca.ca_city,
        CASE WHEN sr.sr_net_loss > 500 THEN 'High' ELSE 'Low' END AS loss_category,
        sr.sr_net_loss AS net_loss
    FROM store_returns sr
    JOIN filtered_dates d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    UNION ALL
    SELECT
        d.d_year,
        cd.cd_gender,
        ca.ca_city,
        CASE WHEN wr.wr_net_loss > 500 THEN 'High' ELSE 'Low' END AS loss_category,
        wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN filtered_dates d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
) combined
GROUP BY d_year, cd_gender, ca_city, loss_category
ORDER BY d_year DESC, total_net_loss DESC
LIMIT 100
