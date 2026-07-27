WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_call_center_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 1000
      AND EXISTS (
          SELECT 1 FROM web_returns wr
          WHERE wr.wr_order_number = cr.cr_order_number
      )
),
joined_data AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        d.d_year,
        fr.cr_return_amount,
        fr.cr_order_number,
        cd.cd_marital_status,
        inv.inv_quantity_on_hand,
        ws.ws_sales_price
    FROM filtered_returns fr
    JOIN call_center cc
        ON fr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d
        ON fr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON fr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON fr.cr_refunded_addr_sk = ca.ca_address_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    WHERE d.d_year = 2001
      AND inv.inv_quantity_on_hand > 700
      AND cd.cd_marital_status = 'M'
)
SELECT
    cc_call_center_id,
    cc_name,
    d_year,
    SUM(cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT cr_order_number) AS distinct_orders,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(cr_return_amount) DESC) AS year_rank,
    AVG(inv_quantity_on_hand) AS avg_inventory_on_return_date,
    MAX(ws_sales_price) AS max_sales_price,
    CASE
        WHEN cd_marital_status = 'M' THEN 'Married'
        ELSE 'Other'
    END AS marital_status_desc
FROM joined_data
GROUP BY cc_call_center_id, cc_name, d_year, cd_marital_status
ORDER BY d_year, year_rank
