WITH sales_base AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_item_sk AS item_sk,
        cp.cp_department AS dept,
        i.i_category AS category,
        i.i_brand AS brand,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amt,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ws.ws_ext_sales_price) AS web_sales_amt,
        SUM(wr.wr_return_amt) AS web_return_amt,
        SUM(sr.sr_return_amt_inc_tax) AS store_return_amt,
        COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 1000 THEN 'high' ELSE 'low' END AS sales_level
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
    WHERE ca.ca_state = 'TX'
      AND i.i_category = 'Electronics'
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
      AND sm.sm_type = 'AIR'
    GROUP BY
        cs.cs_bill_customer_sk,
        cs.cs_item_sk,
        cp.cp_department,
        i.i_category,
        i.i_brand
)
SELECT
    dept,
    item_sk,
    category,
    brand,
    catalog_sales_amt,
    web_sales_amt,
    (store_return_amt + web_return_amt) AS total_return_amt,
    sales_level,
    rnk
FROM (
    SELECT
        dept,
        item_sk,
        category,
        brand,
        catalog_sales_amt,
        web_sales_amt,
        store_return_amt,
        web_return_amt,
        sales_level,
        RANK() OVER (PARTITION BY dept ORDER BY catalog_sales_amt DESC) AS rnk
    FROM sales_base
) t
WHERE rnk <= 5
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = t.item_sk
          AND p2.p_discount_active = 'Y'
    )
ORDER BY dept, rnk
LIMIT 100
