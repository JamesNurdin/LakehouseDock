WITH joined_data AS (
    SELECT DISTINCT
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        d.d_year,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        wr.wr_return_amt,
        wr.wr_net_loss,
        inv.inv_quantity_on_hand,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ca.ca_state,
        ca.ca_city
    FROM catalog_page cp
    JOIN catalog_returns cr
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cp.cp_department = 'Books'
      AND hd.hd_income_band_sk IN (1, 2, 3)
      AND ca.ca_state = 'CA'
      AND inv.inv_quantity_on_hand > 0
),
aggregated AS (
    SELECT
        cp_catalog_page_id,
        cp_department,
        cp_catalog_number,
        cp_catalog_page_number,
        d_year,
        SUM(cr_return_amount) AS total_catalog_return_amount,
        SUM(sr_return_amt) AS total_store_return_amount,
        SUM(wr_return_amt) AS total_web_return_amount,
        SUM(inv_quantity_on_hand) AS total_inventory_on_hand
    FROM joined_data
    GROUP BY cp_catalog_page_id, cp_department, cp_catalog_number, cp_catalog_page_number, d_year
    HAVING SUM(cr_return_amount) > 100
)
SELECT
    cp_catalog_page_id,
    cp_department,
    cp_catalog_number,
    cp_catalog_page_number,
    d_year,
    total_catalog_return_amount,
    total_store_return_amount,
    total_web_return_amount,
    total_inventory_on_hand,
    RANK() OVER (ORDER BY total_catalog_return_amount DESC) AS catalog_return_amount_rank,
    DENSE_RANK() OVER (PARTITION BY cp_department ORDER BY total_store_return_amount DESC) AS store_return_amount_dept_rank,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_web_return_amount DESC) AS web_return_amount_rownum
FROM aggregated
ORDER BY catalog_return_amount_rank
LIMIT 100
