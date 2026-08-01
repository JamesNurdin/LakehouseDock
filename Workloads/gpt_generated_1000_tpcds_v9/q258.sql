WITH avg_price_cte AS (
    SELECT avg(i_current_price) AS avg_price
    FROM item
)
SELECT
    d.d_date,
    i.i_item_id,
    i.i_product_name,
    cs.cs_order_number,
    cs.cs_net_paid_inc_tax AS catalog_net_paid,
    ws.ws_net_paid_inc_tax AS web_net_paid,
    sr.sr_net_loss AS store_return_loss,
    cr.cr_return_amount AS catalog_return_amount,
    wr.wr_return_amt AS web_return_amt,
    cc.cc_name AS call_center_name,
    cp.cp_department,
    r_cr.r_reason_desc AS catalog_return_reason,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY cs.cs_net_paid_inc_tax DESC) AS catalog_sales_rank,
    (SELECT avg_price FROM avg_price_cte) AS avg_item_price
FROM
    date_dim d
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
WHERE
    d.d_year = 2001
    AND i.i_current_price > (SELECT avg_price FROM avg_price_cte)
    AND wp.wp_autogen_flag = 'Y'
    AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = i.i_item_sk
          AND sr2.sr_returned_date_sk = d.d_date_sk
          AND sr2.sr_net_loss > 0
    )
ORDER BY
    d.d_date DESC,
    catalog_sales_rank
LIMIT 100
