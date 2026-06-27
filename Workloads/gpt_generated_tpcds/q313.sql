WITH page_creation AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_type,
        cd.d_date AS page_creation_date,
        cd.d_year AS page_creation_year,
        cd.d_moy AS page_creation_month
    FROM web_page wp
    JOIN date_dim cd ON wp.wp_creation_date_sk = cd.d_date_sk
    WHERE cd.d_date >= DATE '2000-01-01' AND cd.d_date < DATE '2001-01-01'
)
SELECT
    rd.d_year AS return_year,
    rd.d_moy AS return_month,
    pc.wp_type,
    COUNT(DISTINCT pc.wp_web_page_sk) AS distinct_pages_created_2000,
    SUM(wr.wr_return_quantity) AS total_return_quantity,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss
FROM web_returns wr
JOIN date_dim rd ON wr.wr_returned_date_sk = rd.d_date_sk
JOIN page_creation pc ON wr.wr_web_page_sk = pc.wp_web_page_sk
WHERE rd.d_date >= DATE '2001-01-01' AND rd.d_date < DATE '2002-01-01'
GROUP BY rd.d_year, rd.d_moy, pc.wp_type
ORDER BY rd.d_year, rd.d_moy, pc.wp_type
