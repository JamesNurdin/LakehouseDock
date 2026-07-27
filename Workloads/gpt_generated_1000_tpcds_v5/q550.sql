WITH base AS (
    SELECT
        d.d_year,
        i.i_brand,
        i.i_color,
        i.i_size,
        ss.ss_ext_sales_price,
        ws.ws_ext_sales_price,
        sr.sr_net_loss,
        ss.ss_ticket_number,
        ws.ws_order_number,
        ss.ss_coupon_amt,
        ws.ws_coupon_amt,
        inv.inv_quantity_on_hand,
        cc.cc_company_name,
        cc.cc_zip
    FROM
        date_dim d
        JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
            AND sr.sr_item_sk = ss.ss_item_sk
        JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN item i ON i.i_item_sk = ss.ss_item_sk
            AND i.i_item_sk = sr.sr_item_sk
            AND i.i_item_sk = ws.ws_item_sk
        JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
            AND inv.inv_item_sk = i.i_item_sk
        JOIN customer c ON c.c_customer_sk = ss.ss_customer_sk
            AND c.c_customer_sk = sr.sr_customer_sk
            AND c.c_customer_sk = ws.ws_bill_customer_sk
        JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 1998 AND 2000
        AND i.i_brand = 'Brand#12'
        AND i.i_color = 'BLUE'
        AND cc.cc_company_name = 'anti'
        AND cc.cc_zip = '25709'
        AND inv.inv_quantity_on_hand > 0
        AND ss.ss_coupon_amt > 0
),
agg AS (
    SELECT
        d_year,
        i_brand,
        SUM(ss_ext_sales_price) AS store_sales_total,
        SUM(ws_ext_sales_price) AS web_sales_total,
        SUM(sr_net_loss) AS returns_loss,
        COUNT(DISTINCT ss_ticket_number) AS store_txn_cnt,
        COUNT(DISTINCT ws_order_number) AS web_order_cnt,
        AVG(ss_ext_sales_price) AS avg_store_sale,
        GROUPING(d_year) AS g_year,
        GROUPING(i_brand) AS g_brand
    FROM base
    GROUP BY GROUPING SETS (
        (d_year, i_brand),
        (d_year),
        (i_brand),
        ()
    )
    HAVING SUM(ss_ext_sales_price) > 1000
)
SELECT
    d_year,
    i_brand,
    store_sales_total,
    web_sales_total,
    returns_loss,
    store_txn_cnt,
    web_order_cnt,
    avg_store_sale,
    (SELECT AVG(ss_ext_sales_price) FROM store_sales) AS overall_avg_store_sale,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY (store_sales_total + web_sales_total) DESC) AS sales_rank,
    g_year,
    g_brand
FROM agg
ORDER BY
    d_year,
    i_brand,
    g_year,
    g_brand
LIMIT 100
