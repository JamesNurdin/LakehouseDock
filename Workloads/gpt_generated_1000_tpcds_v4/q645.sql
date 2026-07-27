WITH sales_agg AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN store_sales ss
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE cc.cc_state = 'CA'
      AND cp.cp_type = 'U'
      AND cs.cs_list_price > 50
      AND ss.ss_quantity >= 2
      AND ws.ws_net_paid_inc_tax BETWEEN 500 AND 5000
      AND wsit.web_country = 'United States'
      AND cs.cs_ship_cdemo_sk IN (
            SELECT cd2.cd_demo_sk
            FROM customer_demographics cd2
            WHERE cd2.cd_credit_rating = 'Excellent'
          )
    GROUP BY cd.cd_demo_sk, cd.cd_gender
)
SELECT
    cd_demo_sk,
    cd_gender,
    catalog_sales,
    store_sales,
    web_sales,
    (catalog_sales + store_sales + web_sales) AS total_sales,
    AVG(catalog_sales + store_sales + web_sales) OVER () AS avg_total_sales_all,
    ROW_NUMBER() OVER (ORDER BY (catalog_sales + store_sales + web_sales) DESC) AS sales_rank
FROM sales_agg
WHERE (catalog_sales + store_sales + web_sales) > (
        SELECT AVG(catalog_sales) FROM sales_agg
      )
ORDER BY total_sales DESC
LIMIT 100
