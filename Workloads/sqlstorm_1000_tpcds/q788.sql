WITH store_sales_pre AS (
    SELECT
        ss_sold_date_sk AS sold_date_sk,
        ss_item_sk AS item_sk,
        ss_cdemo_sk AS cd_demo_sk,
        ss_quantity AS quantity,
        ss_net_paid AS net_paid,
        ss_net_profit AS net_profit,
        ss_promo_sk AS promo_sk,
        'store' AS channel
    FROM store_sales
), catalog_sales_pre AS (
    SELECT
        cs_sold_date_sk AS sold_date_sk,
        cs_item_sk AS item_sk,
        cs_bill_cdemo_sk AS cd_demo_sk,
        cs_quantity AS quantity,
        cs_net_paid AS net_paid,
        cs_net_profit AS net_profit,
        cs_promo_sk AS promo_sk,
        'catalog' AS channel
    FROM catalog_sales
), web_sales_pre AS (
    SELECT
        ws_sold_date_sk AS sold_date_sk,
        ws_item_sk AS item_sk,
        ws_bill_cdemo_sk AS cd_demo_sk,
        ws_quantity AS quantity,
        ws_net_paid AS net_paid,
        ws_net_profit AS net_profit,
        ws_promo_sk AS promo_sk,
        'web' AS channel
    FROM web_sales
), sales_all AS (
    SELECT * FROM store_sales_pre
    UNION ALL
    SELECT * FROM catalog_sales_pre
    UNION ALL
    SELECT * FROM web_sales_pre
), store_returns_pre AS (
    SELECT
        sr_returned_date_sk AS return_date_sk,
        sr_item_sk AS item_sk,
        sr_return_quantity AS return_quantity,
        sr_net_loss AS net_loss,
        'store' AS channel
    FROM store_returns
), catalog_returns_pre AS (
    SELECT
        cr_returned_date_sk AS return_date_sk,
        cr_item_sk AS item_sk,
        cr_return_quantity AS return_quantity,
        cr_net_loss AS net_loss,
        'catalog' AS channel
    FROM catalog_returns
), web_returns_pre AS (
    SELECT
        wr_returned_date_sk AS return_date_sk,
        wr_item_sk AS item_sk,
        wr_return_quantity AS return_quantity,
        wr_net_loss AS net_loss,
        'web' AS channel
    FROM web_returns
), returns_all AS (
    SELECT * FROM store_returns_pre
    UNION ALL
    SELECT * FROM catalog_returns_pre
    UNION ALL
    SELECT * FROM web_returns_pre
), sales_agg AS (
    SELECT
        s.channel,
        d.d_year,
        d.d_moy,
        s.item_sk,
        s.cd_demo_sk,
        SUM(s.quantity) AS total_qty,
        SUM(s.net_paid) AS total_net_paid,
        SUM(s.net_profit) AS total_net_profit
    FROM sales_all s
    LEFT JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    GROUP BY s.channel, d.d_year, d.d_moy, s.item_sk, s.cd_demo_sk
), returns_agg AS (
    SELECT
        r.channel,
        d.d_year,
        d.d_moy,
        r.item_sk,
        SUM(r.return_quantity) AS total_return_qty,
        SUM(r.net_loss) AS total_return_loss
    FROM returns_all r
    LEFT JOIN date_dim d ON r.return_date_sk = d.d_date_sk
    GROUP BY r.channel, d.d_year, d.d_moy, r.item_sk
), final_agg AS (
    SELECT
        sa.channel,
        sa.d_year,
        sa.d_moy,
        i.i_item_id AS item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        cd.cd_gender,
        sa.total_qty,
        COALESCE(ra.total_return_qty, 0) AS total_return_qty,
        sa.total_net_paid,
        sa.total_net_profit,
        COALESCE(ra.total_return_loss, 0) AS total_return_loss,
        (sa.total_net_profit - COALESCE(ra.total_return_loss, 0)) AS net_profit_after_returns,
        CASE WHEN sa.total_net_paid = 0 THEN NULL
             ELSE (sa.total_net_profit - COALESCE(ra.total_return_loss, 0)) / sa.total_net_paid * 100 END AS profit_margin_pct
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
        ON sa.channel = ra.channel
        AND sa.d_year = ra.d_year
        AND sa.d_moy = ra.d_moy
        AND sa.item_sk = ra.item_sk
    LEFT JOIN item i ON sa.item_sk = i.i_item_sk
    LEFT JOIN customer_demographics cd ON sa.cd_demo_sk = cd.cd_demo_sk
)
SELECT *
FROM (
    SELECT
        channel,
        d_year,
        d_moy,
        item_id,
        i_product_name,
        i_brand,
        i_category,
        cd_gender,
        total_qty,
        total_return_qty,
        total_net_paid,
        net_profit_after_returns,
        round(profit_margin_pct, 2) AS profit_margin_pct,
        ROW_NUMBER() OVER (PARTITION BY channel, d_year, d_moy ORDER BY net_profit_after_returns DESC) AS profit_rank
    FROM final_agg
) ranked
WHERE profit_rank <= 10
ORDER BY channel, d_year, d_moy, profit_rank
