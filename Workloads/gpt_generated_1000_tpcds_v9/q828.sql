WITH base_join AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_number,
        cp.cp_department,
        cp.cp_end_date_sk,
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_suite_number,
        cr.cr_return_amount,
        cr.cr_net_loss AS cr_net_loss,
        cr.cr_return_tax,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_net_loss AS wr_net_loss
    FROM catalog_page cp
    JOIN catalog_returns cr
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_returns wr
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE cp.cp_catalog_page_number IN (16, 14, 19)
      AND cp.cp_end_date_sk BETWEEN 2450874 AND 2451452
      AND ca.ca_suite_number IN ('Suite B', 'Suite 100')
      AND cr.cr_return_amount > 50.0
      AND wr.wr_return_tax > 10.0
),
aggregated AS (
    SELECT
        cp_catalog_page_sk,
        cp_catalog_page_number,
        cp_department,
        ca_city,
        ca_state,
        SUM(cr_return_amount) AS total_cr_return_amount,
        SUM(wr_return_amt) AS total_wr_return_amt,
        SUM(cr_net_loss) + SUM(wr_net_loss) AS total_net_loss
    FROM base_join
    GROUP BY cp_catalog_page_sk, cp_catalog_page_number, cp_department, ca_city, ca_state
)
SELECT
    cp_catalog_page_sk,
    cp_catalog_page_number,
    cp_department,
    ca_city,
    ca_state,
    total_cr_return_amount,
    total_wr_return_amt,
    total_net_loss,
    RANK() OVER (PARTITION BY cp_department ORDER BY total_net_loss DESC) AS dept_rank,
    (SELECT COUNT(*)
       FROM catalog_returns cr2
       WHERE cr2.cr_catalog_page_sk = aggregated.cp_catalog_page_sk
         AND cr2.cr_return_amount > 200.0) AS high_amount_return_cnt
FROM aggregated
WHERE total_net_loss > (
    SELECT AVG(cr_net_loss)
    FROM catalog_returns cr3
    WHERE cr3.cr_catalog_page_sk = aggregated.cp_catalog_page_sk
)
UNION ALL
SELECT
    cp_catalog_page_sk,
    cp_catalog_page_number,
    cp_department,
    ca_city,
    ca_state,
    total_cr_return_amount,
    total_wr_return_amt,
    total_net_loss,
    DENSE_RANK() OVER (PARTITION BY ca_state ORDER BY total_cr_return_amount DESC) AS state_rank,
    (SELECT SUM(cr_return_tax)
       FROM catalog_returns cr4
       WHERE cr4.cr_catalog_page_sk = aggregated.cp_catalog_page_sk) AS total_return_tax
FROM aggregated
WHERE total_cr_return_amount BETWEEN 100.0 AND 5000.0
ORDER BY total_net_loss DESC
LIMIT 100
