WITH sales_filtered AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_item_sk,
        d.d_year,
        d.d_month_seq,
        c.c_email_address,
        wp.wp_url,
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '\\.com$')
      AND wp.wp_url LIKE '%discount%'
)
SELECT
    sf.d_year,
    sf.d_month_seq,
    COUNT(DISTINCT sf.cs_order_number) AS orders,
    SUM(sf.cs_net_profit) AS total_net_profit,
    SUM(cr.cr_net_loss) AS total_return_net_loss,
    ARRAY_AGG(DISTINCT sf.domain) FILTER (WHERE sf.domain IS NOT NULL) AS domains_encountered
FROM sales_filtered sf
LEFT JOIN catalog_returns cr
  ON cr.cr_order_number = sf.cs_order_number
  AND cr.cr_item_sk = sf.cs_item_sk
GROUP BY sf.d_year, sf.d_month_seq
ORDER BY sf.d_year, sf.d_month_seq
