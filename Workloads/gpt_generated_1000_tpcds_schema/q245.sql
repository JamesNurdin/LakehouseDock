WITH catalog_item AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_net_profit,
        cs.cs_wholesale_cost,
        cs.cs_ext_tax,
        cs.cs_ext_ship_cost,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_rec_start_date,
        i.i_rec_end_date,
        i.i_size
    FROM tpcds.catalog_sales cs
    FULL OUTER JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE
        i.i_rec_start_date >= DATE '1999-01-01'
        AND i.i_rec_end_date <= DATE '2000-12-31'
        AND i.i_size IN ('large', 'extra large')
        AND (cs.cs_wholesale_cost > 30 OR cs.cs_wholesale_cost IS NULL)
        AND (cs.cs_ext_tax < 150 OR cs.cs_ext_tax IS NULL)
),
store_sales_join AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_net_profit,
        ss.ss_net_paid_inc_tax,
        ss.ss_quantity,
        ss.ss_ticket_number,
        i.i_item_id
    FROM tpcds.store_sales ss
    JOIN tpcds.item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE
        ss.ss_wholesale_cost BETWEEN 50 AND 500
        AND ss.ss_net_paid_inc_tax > 1000
),
returns_join AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_return_amt,
        sr.sr_store_credit,
        sr.sr_ticket_number
    FROM tpcds.store_returns sr
    JOIN tpcds.store_sales ss
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    WHERE
        sr.sr_return_amt > 20
        AND sr.sr_store_credit > 0
)
SELECT
    ci.i_item_id,
    ci.i_product_name,
    ci.i_category,
    SUM(ci.cs_net_profit) AS total_catalog_net_profit,
    SUM(ssj.ss_net_profit) AS total_store_net_profit,
    (
        SELECT SUM(rj.sr_return_amt)
        FROM returns_join rj
        WHERE rj.sr_item_sk = ci.cs_item_sk
    ) AS total_return_amount,
    RANK() OVER (ORDER BY (SUM(ci.cs_net_profit) + SUM(ssj.ss_net_profit)) DESC) AS profit_rank
FROM catalog_item ci
LEFT JOIN store_sales_join ssj
    ON ci.cs_item_sk = ssj.ss_item_sk
GROUP BY
    ci.i_item_id,
    ci.i_product_name,
    ci.i_category,
    ci.cs_item_sk
ORDER BY profit_rank
LIMIT 100
