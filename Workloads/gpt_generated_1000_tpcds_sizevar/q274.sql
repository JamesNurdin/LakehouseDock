WITH rs AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_returned_date_sk,
        sr.sr_customer_sk,
        sr.sr_reason_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2001
    )
    GROUP BY sr.sr_item_sk, sr.sr_returned_date_sk, sr.sr_customer_sk, sr.sr_reason_sk
),
inv_agg AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_date_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk, inv.inv_date_sk
),
cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_quantity > 5
)
SELECT
    i.i_item_id,
    i.i_brand,
    d.d_year,
    CASE WHEN rs.total_return_amt > 1000 THEN 'High' ELSE 'Low' END AS return_level,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
    SUM(ws.ws_ext_sales_price) AS web_sales_amount,
    SUM(rs.total_return_amt) AS total_return_amount,
    COUNT(DISTINCT rs.sr_customer_sk) AS distinct_return_customers,
    AVG(ia.total_qty_on_hand) AS avg_inventory_on_hand
FROM rs
JOIN item i
    ON i.i_item_sk = rs.sr_item_sk
JOIN date_dim d
    ON d.d_date_sk = rs.sr_returned_date_sk
JOIN inv_agg ia
    ON ia.inv_item_sk = i.i_item_sk
   AND ia.inv_date_sk = d.d_date_sk
JOIN cs_sample cs
    ON cs.cs_item_sk = i.i_item_sk
   AND cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer cust
    ON cs.cs_bill_customer_sk = cust.c_customer_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN reason r
    ON rs.sr_reason_sk = r.r_reason_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
WHERE
    cd.cd_gender = 'F'
    AND p.p_channel_email = 'N'
    AND we.web_state = 'CA'
GROUP BY
    i.i_item_id,
    i.i_brand,
    d.d_year,
    CASE WHEN rs.total_return_amt > 1000 THEN 'High' ELSE 'Low' END
ORDER BY catalog_sales_amount DESC
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY
