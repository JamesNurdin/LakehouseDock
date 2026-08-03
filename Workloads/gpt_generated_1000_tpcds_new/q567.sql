WITH distinct_items AS (
    SELECT DISTINCT
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category
    FROM
        tpcds.item i
    WHERE
        i.i_brand = 'Brand#12'
),
inv_agg AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_date_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM
        tpcds.inventory inv TABLESAMPLE BERNOULLI (10)
    GROUP BY
        inv.inv_item_sk,
        inv.inv_date_sk
)
SELECT
    d.d_year,
    di.i_item_id,
    di.i_brand,
    di.i_category,
    cs.cs_ext_sales_price,
    cs.cs_quantity,
    inv_agg.total_qty_on_hand,
    sr.sr_return_amt,
    wr.wr_return_amt,
    ROW_NUMBER() OVER (PARTITION BY di.i_category ORDER BY cs.cs_ext_sales_price DESC) AS sales_rank,
    LAG(cs.cs_ext_sales_price) OVER (PARTITION BY di.i_category ORDER BY d.d_date) AS prev_day_sales,
    (SELECT SUM(sr2.sr_return_amt)
     FROM tpcds.store_returns sr2
     WHERE sr2.sr_item_sk = di.i_item_sk
       AND sr2.sr_returned_date_sk = d.d_date_sk) AS total_item_return_amount
FROM
    tpcds.date_dim d
JOIN tpcds.catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN tpcds.customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN tpcds.customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN distinct_items di
    ON cs.cs_item_sk = di.i_item_sk
JOIN inv_agg
    ON inv_agg.inv_item_sk = di.i_item_sk
   AND inv_agg.inv_date_sk = d.d_date_sk
LEFT JOIN tpcds.store_returns sr
    ON sr.sr_item_sk = di.i_item_sk
   AND sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN tpcds.web_returns wr
    ON wr.wr_item_sk = di.i_item_sk
   AND wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN tpcds.web_page wp
    ON wp.wp_web_page_sk = wr.wr_web_page_sk
WHERE
    d.d_year = 2001
    AND cs.cs_ext_ship_cost > 500
    AND sr.sr_net_loss > 20
    AND EXISTS (
        SELECT 1
        FROM tpcds.web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
          AND wp2.wp_url IS NOT NULL
    )
GROUP BY
    d.d_year,
    di.i_item_id,
    di.i_brand,
    di.i_category,
    cs.cs_ext_sales_price,
    cs.cs_quantity,
    inv_agg.total_qty_on_hand,
    sr.sr_return_amt,
    wr.wr_return_amt,
    di.i_item_sk,
    d.d_date_sk,
    d.d_date
ORDER BY
    d.d_year,
    di.i_category,
    sales_rank
