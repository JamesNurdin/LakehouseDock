WITH sampled_items AS (
    SELECT i_item_sk, i_item_id, i_current_price
    FROM item TABLESAMPLE BERNOULLI (10)
),
base_join AS (
    SELECT
        cp.cp_catalog_page_id,
        cs.cs_order_number,
        c.c_customer_id,
        cd.cd_gender,
        i.i_item_id,
        s.s_store_id,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        w.w_warehouse_id,
        wr.wr_return_quantity,
        ss2.ss_quantity AS prior_quantity,
        LAG(ss.ss_quantity) OVER (PARTITION BY c.c_customer_id ORDER BY ss.ss_sold_date_sk) AS lag_quantity,
        r.total_return_amt,
        ss.ss_ticket_number
    FROM catalog_page cp
    JOIN catalog_sales cs
        ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN sampled_items i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
       AND ss.ss_customer_sk = c.c_customer_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    JOIN store_sales ss2
        ON ss2.ss_ticket_number = ss.ss_ticket_number
       AND ss2.ss_sold_date_sk < ss.ss_sold_date_sk
    LEFT JOIN LATERAL (
        SELECT sum(sr2.sr_return_amt) AS total_return_amt
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = i.i_item_sk
    ) r ON true
    WHERE cd.cd_purchase_estimate > 5000
)
SELECT
    cp_catalog_page_id,
    cs_order_number,
    c_customer_id,
    cd_gender,
    i_item_id,
    s_store_id,
    ss_quantity,
    ss_ext_sales_price,
    w_warehouse_id,
    wr_return_quantity,
    prior_quantity,
    lag_quantity,
    total_return_amt
FROM base_join bj
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr_check
    WHERE sr_check.sr_ticket_number = bj.ss_ticket_number
      AND sr_check.sr_return_amt > 0
)
EXCEPT
SELECT
    cp_catalog_page_id,
    cs_order_number,
    c_customer_id,
    cd_gender,
    i_item_id,
    s_store_id,
    ss_quantity,
    ss_ext_sales_price,
    w_warehouse_id,
    wr_return_quantity,
    prior_quantity,
    lag_quantity,
    total_return_amt
FROM (
    SELECT
        cp.cp_catalog_page_id,
        cs.cs_order_number,
        c.c_customer_id,
        cd.cd_gender,
        i.i_item_id,
        s.s_store_id,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        w.w_warehouse_id,
        wr.wr_return_quantity,
        ss2.ss_quantity AS prior_quantity,
        LAG(ss.ss_quantity) OVER (PARTITION BY c.c_customer_id ORDER BY ss.ss_sold_date_sk) AS lag_quantity,
        r.total_return_amt
    FROM catalog_page cp
    JOIN catalog_sales cs
        ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN sampled_items i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
       AND ss.ss_customer_sk = c.c_customer_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    JOIN store_sales ss2
        ON ss2.ss_ticket_number = ss.ss_ticket_number
       AND ss2.ss_sold_date_sk < ss.ss_sold_date_sk
    LEFT JOIN LATERAL (
        SELECT sum(sr3.sr_return_amt) AS total_return_amt
        FROM store_returns sr3
        WHERE sr3.sr_item_sk = i.i_item_sk
    ) r ON true
    WHERE cp.cp_catalog_page_number = 14
) exclude_set
LIMIT 100
