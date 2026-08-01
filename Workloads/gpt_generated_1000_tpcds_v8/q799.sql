WITH base AS (
    SELECT
        d.d_year,
        s.s_store_name,
        r.r_reason_desc,
        cr.cr_net_loss,
        sr.sr_net_loss,
        wr.wr_net_loss,
        c.c_customer_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE d.d_year = (SELECT MAX(d_year) FROM date_dim WHERE d_year < 2005)
      AND s.s_state = 'CA'
      AND ca.ca_country = 'United States'
),

sr_agg AS (
    SELECT r.r_reason_desc,
           SUM(sr.sr_net_loss) AS sr_net_loss_total
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY r.r_reason_desc
),

wr_agg AS (
    SELECT r.r_reason_desc,
           SUM(wr.wr_net_loss) AS wr_net_loss_total
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY r.r_reason_desc
),

full_reason AS (
    SELECT COALESCE(sr.r_reason_desc, wr.r_reason_desc) AS reason_desc,
           sr.sr_net_loss_total,
           wr.wr_net_loss_total
    FROM sr_agg sr
    FULL OUTER JOIN wr_agg wr
      ON sr.r_reason_desc = wr.r_reason_desc
)
SELECT
    d_year,
    s_store_name,
    reason_desc,
    SUM(cr_net_loss) AS total_catalog_net_loss,
    SUM(sr_net_loss) AS total_store_return_net_loss,
    SUM(wr_net_loss) AS total_web_return_net_loss,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers,
    SUM(SUM(cr_net_loss)) OVER (PARTITION BY d_year ORDER BY d_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_catalog_net_loss,
    full_reason.sr_net_loss_total,
    full_reason.wr_net_loss_total,
    (SELECT COUNT(*)
       FROM (SELECT ws_bill_customer_sk AS cust_sk FROM web_sales
             EXCEPT
             SELECT ss_customer_sk FROM store_sales) exc) AS exclusive_web_customers
FROM base
LEFT JOIN full_reason ON base.r_reason_desc = full_reason.reason_desc
GROUP BY ROLLUP (d_year, s_store_name, reason_desc),
         full_reason.sr_net_loss_total,
         full_reason.wr_net_loss_total
HAVING SUM(cr_net_loss) > 0
ORDER BY d_year NULLS LAST,
         s_store_name NULLS LAST,
         reason_desc NULLS LAST
LIMIT 100
