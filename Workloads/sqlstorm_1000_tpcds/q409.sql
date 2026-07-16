WITH returns_agg AS (
    SELECT
        sr_ticket_number,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_net_loss) AS total_net_loss
    FROM store_returns
    GROUP BY sr_ticket_number
),
sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        s.s_store_name,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        AVG(p.p_cost) AS avg_promo_cost,
        SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory_on_day,
        SUM(COALESCE(r.total_return_amt, 0)) AS total_return_amount,
        SUM(COALESCE(r.total_net_loss, 0)) AS total_return_net_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = ss.ss_item_sk AND inv.inv_date_sk = d.d_date_sk
    INNER JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN returns_agg r ON ss.ss_ticket_number = r.sr_ticket_number
    WHERE d.d_year BETWEEN 2000 AND 2001
      AND cd.cd_gender = 'M'
    GROUP BY d.d_year, d.d_month_seq, i.i_category, s.s_store_name
    HAVING SUM(ss.ss_ext_sales_price) > 10000
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    s_store_name,
    total_profit,
    total_sales,
    distinct_customers,
    avg_promo_cost,
    total_inventory_on_day,
    total_return_amount,
    total_return_net_loss,
    RANK() OVER (PARTITION BY d_year, i_category ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY d_year, d_month_seq, profit_rank
LIMIT 100
