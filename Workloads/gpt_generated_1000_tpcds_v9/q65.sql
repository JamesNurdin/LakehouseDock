WITH
catalog_agg AS (
    SELECT
        i.i_category AS product_category,
        d_sold.d_year AS sales_year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss) AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    JOIN item i_cr
        ON cr.cr_item_sk = i_cr.i_item_sk
    JOIN date_dim d_returned
        ON cr.cr_returned_date_sk = d_returned.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd_refunded
        ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN customer_demographics cd_returning
        ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    GROUP BY
        i.i_category,
        d_sold.d_year
),
store_ws_agg AS (
    SELECT
        i2.i_category AS product_category,
        d_ret.d_year AS sales_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(ws.ws_net_profit) - SUM(sr.sr_net_loss) AS net_profit
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN item i2
        ON sr.sr_item_sk = i2.i_item_sk
    JOIN customer_demographics cd_store_cust
        ON sr.sr_cdemo_sk = cd_store_cust.cd_demo_sk
    JOIN reason r2
        ON sr.sr_reason_sk = r2.r_reason_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i2.i_item_sk
    JOIN date_dim d_inv
        ON inv.inv_date_sk = d_inv.d_date_sk
    -- web sales joins
    JOIN web_sales ws
        ON ws.ws_item_sk = i2.i_item_sk
    JOIN date_dim d_ws_sold
        ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN date_dim d_ws_ship
        ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN customer_demographics cd_ws_bill
        ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
    JOIN customer_demographics cd_ws_ship
        ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN date_dim d_ws_open
        ON wsite.web_open_date_sk = d_ws_open.d_date_sk
    JOIN date_dim d_ws_close
        ON wsite.web_close_date_sk = d_ws_close.d_date_sk
    GROUP BY
        i2.i_category,
        d_ret.d_year
)

SELECT DISTINCT
    product_category,
    sales_year,
    total_sales,
    total_return_amount,
    net_profit,
    SUM(total_sales) OVER (PARTITION BY sales_year) AS sales_year_total,
    RANK() OVER (PARTITION BY sales_year ORDER BY net_profit DESC) AS profit_rank
FROM (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM store_ws_agg
) AS combined
ORDER BY
    sales_year DESC,
    profit_rank
LIMIT 100
