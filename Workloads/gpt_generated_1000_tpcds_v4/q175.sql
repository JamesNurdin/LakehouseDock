/* goal: Analyze catalog sales, store sales and returns for California stores, broken down by customer gender, and compare against overall average store sales net paid */
WITH base AS (
    SELECT
        s.s_store_name,
        cd.cd_gender,
        cs.cs_order_number,
        cs.cs_net_paid,
        ss.ss_net_paid,
        sr.sr_net_loss
    FROM
        catalog_sales cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        JOIN store s2 ON sr.sr_store_sk = s2.s_store_sk
        JOIN customer_address ca2 ON sr.sr_addr_sk = ca2.ca_address_sk
        JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE
        s.s_state = 'CA'
        AND cd.cd_marital_status = 'M'
)
SELECT
    b.s_store_name,
    b.cd_gender,
    COUNT(DISTINCT b.cs_order_number) AS orders,
    SUM(b.cs_net_paid) AS catalog_sales_net_paid,
    SUM(b.sr_net_loss) AS store_returns_net_loss,
    SUM(b.ss_net_paid) AS store_sales_net_paid,
    (SELECT AVG(ss2.ss_net_paid) FROM store_sales ss2) AS avg_store_sales_net_paid
FROM
    base b
GROUP BY
    b.s_store_name,
    b.cd_gender
ORDER BY
    catalog_sales_net_paid DESC
LIMIT 100
