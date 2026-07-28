WITH returns_agg AS (
    SELECT
        wr_web_page_sk,
        COUNT(*) AS return_cnt,
        SUM(wr_return_amt) AS total_return_amt,
        AVG(wr_return_tax) AS avg_return_tax,
        MIN(wr_return_quantity) AS min_return_qty,
        MAX(wr_return_quantity) AS max_return_qty
    FROM web_returns
    WHERE wr_return_tax > 20.00
      AND wr_return_amt > 50.00
      AND wr_refunded_hdemo_sk IN (1870, 4472, 2641)
      AND wr_returning_addr_sk BETWEEN 5000000 AND 6000000
    GROUP BY wr_web_page_sk
)
SELECT
    wp.wp_type,
    wp.wp_autogen_flag,
    wp.wp_max_ad_count,
    COUNT(DISTINCT wp.wp_web_page_sk) AS page_cnt,
    SUM(r.total_return_amt) AS sum_return_amt,
    AVG(r.avg_return_tax) AS avg_return_tax_across_pages,
    SUM(r.return_cnt) AS total_returns,
    MIN(r.min_return_qty) AS overall_min_qty,
    MAX(r.max_return_qty) AS overall_max_qty
FROM web_page wp
JOIN returns_agg r
    ON wp.wp_web_page_sk = r.wr_web_page_sk
WHERE wp.wp_autogen_flag = 'N'
  AND wp.wp_max_ad_count >= 2
  AND wp.wp_link_count BETWEEN 10 AND 20
  AND wp.wp_char_count > 5000
GROUP BY wp.wp_type, wp.wp_autogen_flag, wp.wp_max_ad_count
ORDER BY sum_return_amt DESC
LIMIT 100
