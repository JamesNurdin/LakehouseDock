WITH
    catalog_sales_filtered AS (
        SELECT
            cs.cs_call_center_sk,
            cs.cs_catalog_page_sk,
            cs.cs_bill_addr_sk,
            cs.cs_ship_addr_sk,
            cs.cs_ext_sales_price,
            cs.cs_quantity,
            cc.cc_call_center_id,
            cc.cc_state,
            cp.cp_type,
            cp.cp_department
        FROM catalog_sales cs
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE cs.cs_ext_sales_price > 500
          AND cs.cs_quantity >= 1
          AND cc.cc_state = 'CA'
          AND cp.cp_type = 'I'
          AND cp.cp_department IN ('Electronics', 'Books')
    ),
    sales_by_address AS (
        SELECT
            ca.ca_address_sk,
            ca.ca_city,
            ca.ca_state,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            SUM(ss.ss_net_profit) AS total_profit
        FROM store_sales ss
        JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        JOIN customer_address ca
            ON ss.ss_addr_sk = ca.ca_address_sk
        WHERE ss.ss_quantity > 0
          AND s.s_state = 'CA'
          AND ca.ca_state = 'CA'
        GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
        HAVING SUM(ss.ss_ext_sales_price) > 1000
    ),
    web_returns_by_address AS (
        SELECT
            ca.ca_address_sk,
            ca.ca_city,
            ca.ca_state,
            SUM(wr.wr_return_amt_inc_tax) AS total_web_returns,
            SUM(wr.wr_net_loss) AS total_web_loss
        FROM web_returns wr
        JOIN customer_address ca
            ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        WHERE wr.wr_return_amt_inc_tax > 0
          AND ca.ca_state = 'CA'
        GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
    ),
    store_returns_by_address AS (
        SELECT
            ca.ca_address_sk,
            SUM(sr.sr_return_amt_inc_tax) AS total_store_returns,
            SUM(sr.sr_net_loss) AS total_store_loss
        FROM store_returns sr
        JOIN customer_address ca
            ON sr.sr_addr_sk = ca.ca_address_sk
        WHERE sr.sr_return_amt_inc_tax > 0
          AND sr.sr_return_quantity > 0
        GROUP BY ca.ca_address_sk
    ),
    combined_sales_returns AS (
        SELECT
            COALESCE(sba.ca_address_sk, wrba.ca_address_sk) AS address_sk,
            COALESCE(sba.ca_city, wrba.ca_city) AS city,
            COALESCE(sba.ca_state, wrba.ca_state) AS state,
            sba.total_sales,
            sba.total_profit,
            wrba.total_web_returns,
            wrba.total_web_loss,
            srba.total_store_returns,
            srba.total_store_loss
        FROM sales_by_address sba
        FULL OUTER JOIN web_returns_by_address wrba
            ON sba.ca_address_sk = wrba.ca_address_sk
        LEFT JOIN store_returns_by_address srba
            ON COALESCE(sba.ca_address_sk, wrba.ca_address_sk) = srba.ca_address_sk
    ),
    distinct_call_center_per_addr AS (
        SELECT
            address_sk,
            COUNT(DISTINCT cc_call_center_id) AS distinct_cc_count
        FROM (
            SELECT cs.cs_bill_addr_sk AS address_sk, cc.cc_call_center_id
            FROM catalog_sales_filtered cs
            JOIN call_center cc
                ON cs.cs_call_center_sk = cc.cc_call_center_sk
            UNION ALL
            SELECT cs.cs_ship_addr_sk AS address_sk, cc.cc_call_center_id
            FROM catalog_sales_filtered cs
            JOIN call_center cc
                ON cs.cs_call_center_sk = cc.cc_call_center_sk
        )
        GROUP BY address_sk
    )
SELECT
    csdr.address_sk,
    csdr.city,
    csdr.state,
    csdr.total_sales,
    csdr.total_profit,
    CASE
        WHEN csdr.total_profit > 10000 THEN 'High'
        WHEN csdr.total_profit > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    csdr.total_web_returns,
    csdr.total_store_returns,
    RANK() OVER (ORDER BY csdr.total_sales DESC) AS sales_rank,
    SUM(csdr.total_sales) OVER (
        ORDER BY csdr.total_sales DESC
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_3_sales,
    COALESCE(dcc.distinct_cc_count, 0) AS distinct_call_center_cnt
FROM combined_sales_returns csdr
LEFT JOIN distinct_call_center_per_addr dcc
    ON csdr.address_sk = dcc.address_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales_filtered csf
    WHERE csf.cs_bill_addr_sk = csdr.address_sk
       OR csf.cs_ship_addr_sk = csdr.address_sk
)
ORDER BY csdr.total_sales DESC
LIMIT 100
