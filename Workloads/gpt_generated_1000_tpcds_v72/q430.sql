WITH joined_fact AS (
    SELECT
        cc.cc_call_center_sk,
        cs.cs_sold_date_sk               AS cs_sold_date_sk,
        cs.cs_item_sk                    AS cs_item_sk,
        cs.cs_order_number               AS cs_order_number,
        cs.cs_warehouse_sk               AS cs_warehouse_sk,
        cs.cs_ext_sales_price            AS cs_ext_sales_price,
        cs.cs_quantity                   AS cs_quantity,
        cs.cs_net_profit                 AS cs_net_profit,
        cr.cr_returned_date_sk           AS cr_returned_date_sk,
        cr.cr_reason_sk                  AS cr_reason_sk,
        cr.cr_return_amount              AS cr_return_amount,
        d_cs.d_year                      AS cs_year,
        d_cs.d_month_seq                 AS cs_month_seq,
        i.i_item_sk                      AS i_item_sk,
        i.i_category                     AS i_category,
        i.i_category_id                  AS i_category_id,
        i.i_brand_id                     AS i_brand_id,
        ca.ca_country                    AS ca_country,
        ca.ca_address_sk                 AS ca_address_sk,
        s.s_store_sk                     AS s_store_sk,
        s.s_store_name                   AS s_store_name,
        s.s_state                        AS s_state,
        ss.ss_sold_date_sk               AS ss_sold_date_sk,
        ss.ss_ticket_number              AS ss_ticket_number,
        sr.sr_returned_date_sk           AS sr_returned_date_sk,
        sr.sr_return_amt                 AS sr_return_amt,
        inv.inv_quantity_on_hand         AS inv_quantity_on_hand,
        w.w_warehouse_sk                 AS w_warehouse_sk,
        r.r_reason_desc                  AS return_reason_desc,
        wp.wp_web_page_id                AS wp_web_page_id,
        wr.wr_return_amt                 AS web_return_amt
    FROM call_center cc
    JOIN catalog_sales cs
        ON cc.cc_call_center_sk = cs.cs_call_center_sk
    JOIN date_dim d_cs
        ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN catalog_returns cr
        ON cc.cc_call_center_sk = cr.cr_call_center_sk
        AND cs.cs_order_number = cr.cr_order_number
    JOIN date_dim d_cr
        ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_sold_date_sk = cs.cs_sold_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_ss
        ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d_cs.d_date_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_page wp
        ON wp.wp_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d_cs.d_date_sk
    WHERE d_cs.d_year = 2001                                      -- predicate 1
      AND ca.ca_country = 'United States'                         -- predicate 2
      AND i.i_category_id IN (7, 8, 9)                            -- predicate 3
      AND s.s_state = 'GA'                                         -- predicate 4
      AND cs.cs_quantity > 0                                      -- predicate 5
      AND inv.inv_quantity_on_hand > 0                            -- predicate 6
      AND EXISTS (
            SELECT 1
            FROM catalog_sales cs2
            WHERE cs2.cs_call_center_sk = cc.cc_call_center_sk
              AND cs2.cs_net_profit > 0
        )                                                          -- sub‑query predicate
),
aggregated AS (
    SELECT
        s_store_sk,
        s_store_name,
        i_category,
        cs_year,
        cs_month_seq,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(COALESCE(sr_return_amt, 0)) AS total_returns,
        SUM(cs_ext_sales_price) - SUM(COALESCE(sr_return_amt, 0)) AS net_sales
    FROM joined_fact
    GROUP BY s_store_sk, s_store_name, i_category, cs_year, cs_month_seq
    HAVING SUM(cs_ext_sales_price) > 10000                       -- additional filter
)
SELECT
    s_store_name,
    i_category,
    cs_year,
    cs_month_seq,
    total_sales,
    total_returns,
    net_sales,
    RANK() OVER (PARTITION BY cs_year ORDER BY net_sales DESC) AS profit_rank,
    AVG(net_sales) OVER (
        PARTITION BY s_store_sk
        ORDER BY cs_month_seq
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_3m
FROM aggregated
ORDER BY net_sales DESC
LIMIT 100
