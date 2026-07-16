WITH combined_sales AS (
    SELECT 'STORE' AS sales_channel,
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_sold_time_sk AS sold_time_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_store_sk AS store_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_promo_sk AS promo_sk
    FROM store_sales ss
    UNION ALL
    SELECT 'CATALOG' AS sales_channel,
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_sold_time_sk AS sold_time_sk,
        cs.cs_item_sk AS item_sk,
        NULL AS store_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_promo_sk AS promo_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT 'WEB' AS sales_channel,
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_sold_time_sk AS sold_time_sk,
        ws.ws_item_sk AS item_sk,
        NULL AS store_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_promo_sk AS promo_sk
    FROM web_sales ws
),
sales_with_returns AS (
    SELECT cs.sales_channel,
        cs.sold_date_sk,
        cs.sold_time_sk,
        cs.item_sk,
        cs.store_sk,
        cs.customer_sk,
        cs.quantity,
        cs.net_paid,
        cs.net_profit,
        cs.promo_sk,
        COALESCE(sr.sr_return_quantity, cr.cr_return_quantity, wr.wr_return_quantity) AS return_quantity,
        COALESCE(sr.sr_net_loss, cr.cr_net_loss, wr.wr_net_loss) AS net_loss,
        CASE
            WHEN cs.sales_channel = 'STORE' THEN 'Store Return'
            WHEN cs.sales_channel = 'CATALOG' THEN 'Catalog Return'
            WHEN cs.sales_channel = 'WEB' THEN 'Web Return'
            ELSE 'No Return'
        END AS return_type
    FROM combined_sales cs
    LEFT JOIN store_returns sr
        ON cs.sales_channel = 'STORE'
        AND cs.sold_date_sk = sr.sr_returned_date_sk
        AND cs.item_sk = sr.sr_item_sk
        AND cs.customer_sk = sr.sr_customer_sk
    LEFT JOIN catalog_returns cr
        ON cs.sales_channel = 'CATALOG'
        AND cs.sold_date_sk = cr.cr_returned_date_sk
        AND cs.item_sk = cr.cr_item_sk
        AND cs.customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN web_returns wr
        ON cs.sales_channel = 'WEB'
        AND cs.sold_date_sk = wr.wr_returned_date_sk
        AND cs.item_sk = wr.wr_item_sk
        AND cs.customer_sk = wr.wr_refunded_customer_sk
),
customer_detail AS (
    SELECT c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential,
        d.d_year,
        d.d_month_seq,
        d.d_date,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY d.d_date DESC) AS rn
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
)
SELECT
    swr.sales_channel,
    swr.sold_date_sk,
    d.d_date,
    i.i_product_name,
    concat_ws(' ', c.c_first_name, c.c_last_name) AS customer_name,
    swr.quantity,
    swr.net_paid,
    swr.net_profit,
    swr.return_quantity,
    swr.net_loss,
    swr.return_type,
    CASE WHEN swr.net_profit < 0 THEN 'Loss' ELSE 'Profit' END AS profit_flag,
    COALESCE(p.p_cost, 0) AS promo_cost,
    SUM(swr.net_paid) OVER (PARTITION BY swr.sales_channel, swr.sold_date_sk) AS daily_channel_total,
    RANK() OVER (PARTITION BY swr.sales_channel ORDER BY swr.net_profit DESC) AS profit_rank,
    (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_item_sk = swr.item_sk AND sr2.sr_returned_date_sk = swr.sold_date_sk) AS store_return_count,
    (SELECT AVG(s2.net_profit) FROM sales_with_returns s2 WHERE s2.item_sk = swr.item_sk) AS avg_item_profit,
    ROW_NUMBER() OVER (PARTITION BY swr.sales_channel ORDER BY swr.sold_date_sk, swr.item_sk) AS row_seq
FROM sales_with_returns swr
LEFT JOIN item i ON swr.item_sk = i.i_item_sk
LEFT JOIN customer_detail c ON swr.customer_sk = c.c_customer_sk AND c.rn = 1
LEFT JOIN promotion p ON swr.promo_sk = p.p_promo_sk
LEFT JOIN date_dim d ON swr.sold_date_sk = d.d_date_sk
WHERE
    d.d_year BETWEEN 1998 AND 2000
    AND (swr.net_profit > 0 OR swr.return_quantity IS NOT NULL)
    AND (COALESCE(swr.return_quantity, 0) > 0 OR swr.sales_channel <> 'WEB')
