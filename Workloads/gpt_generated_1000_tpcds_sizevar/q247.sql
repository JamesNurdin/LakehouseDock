WITH full_joined AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_ext_sales_price,
        wr.wr_return_amt,
        ws.ws_web_site_sk,
        CASE 
            WHEN ws.ws_ext_sales_price IS NOT NULL AND wr.wr_return_amt IS NOT NULL THEN 'Both'
            WHEN ws.ws_ext_sales_price IS NOT NULL THEN 'Sale Only'
            ELSE 'Return Only'
        END AS record_type
    FROM web_sales ws
    FULL OUTER JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
)
SELECT
    order_number,
    ws_ext_sales_price,
    wr_return_amt,
    sale_category,
    web_company_name,
    record_type
FROM (
    SELECT
        fj.ws_order_number AS order_number,
        fj.ws_ext_sales_price,
        fj.wr_return_amt,
        CASE WHEN fj.ws_ext_sales_price > 1000 THEN 'HighSale' ELSE 'LowSale' END AS sale_category,
        site.web_company_name,
        fj.record_type
    FROM full_joined fj
    JOIN web_site site
        ON fj.ws_web_site_sk = site.web_site_sk
    WHERE site.web_company_name = 'able'
      AND fj.record_type <> 'Return Only'

    UNION ALL

    SELECT
        fj.ws_order_number AS order_number,
        fj.ws_ext_sales_price,
        fj.wr_return_amt,
        CASE WHEN fj.wr_return_amt > 500 THEN 'HighReturn' ELSE 'LowReturn' END AS sale_category,
        site.web_company_name,
        fj.record_type
    FROM full_joined fj
    LEFT JOIN web_site site
        ON fj.ws_web_site_sk = site.web_site_sk
    WHERE fj.record_type = 'Return Only'
      AND (SELECT COUNT(*) FROM web_site s2 WHERE s2.web_zip = '78048') > 0
) AS combined
ORDER BY sale_category DESC, order_number
LIMIT 100
